using UnityEngine;
using System.Collections.Generic;

public class MapGenerator : MonoBehaviour
{
    public GameObject cubePrefab;
    public float spacing = 1.1f;
    public static Dictionary<string, Square> AllSquares = new Dictionary<string, Square>();

    // 【修正1】GameManagerより確実に先にマップを作るため Awake に変更
    void Awake()
    {
        GenerateMap();
    }

    public void GenerateMap()
    {
        // 既存削除
        foreach (Transform child in transform) Destroy(child.gameObject);
        AllSquares.Clear();

        // 【修正2】"Block"レイヤーのIDを取得
        int blockLayerIndex = LayerMask.NameToLayer("Block");

        int size = 5;

        for (int x = 0; x < size; x++)
        {
            for (int y = 0; y < size; y++)
            {
                for (int z = 0; z < size; z++)
                {
                    string face = GetFaceName(x, y, z, size);
                    if (face == "Inner") continue;

                    GameObject obj = Instantiate(cubePrefab, transform);
                    obj.transform.position = new Vector3(x * spacing, y * spacing, z * spacing);
                    obj.name = $"Cube_{x}_{y}_{z}";
                    
                    // Hierarchyを整理するため親を設定（任意ですが推奨）
                    obj.transform.parent = transform;

                    // 【修正2の続き】生成したブロックにレイヤーを適用
                    // これがないと GameManager の Raycast が当たりません
                    if (blockLayerIndex != -1)
                    {
                        obj.layer = blockLayerIndex;
                    }
                    else
                    {
                        Debug.LogWarning("Layer 'Block' が見つかりません。UnityエディタのLayers設定を確認してください。");
                    }

                    Square sq = obj.GetComponent<Square>();
                    if (sq == null) sq = obj.AddComponent<Square>();

                    // ID生成
                    sq.ID = $"{face}_{x}_{z}";
                    if (face == "Front" || face == "Back") sq.ID = $"{face}_{x}_{y}";
                    if (face == "Left" || face == "Right") sq.ID = $"{face}_{z}_{y}";

                    sq.FaceName = face;
                    sq.IsBlocked = (face == "Bottom"); 

                    if (!AllSquares.ContainsKey(sq.ID)) AllSquares.Add(sq.ID, sq);
                    else sq.ID += "_dup";
                }
            }
        }
        // 隣接接続の計算
        ConnectNeighbors();
        Debug.Log($"マップ生成完了: {AllSquares.Count}個");
    }

    string GetFaceName(int x, int y, int z, int size)
    {
        if (y == 0) return "Bottom";
        if (y == size - 1) return "Top";
        if (x == 0) return "Left";
        if (x == size - 1) return "Right";
        if (z == 0) return "Back";
        if (z == size - 1) return "Front";
        return "Inner";
    }

    void ConnectNeighbors()
    {
        foreach (var kvp in AllSquares)
        {
            Square current = kvp.Value;
            current.ConnectedIds.Clear();
            foreach (var targetKvp in AllSquares)
            {
                Square target = targetKvp.Value;
                if (current == target) continue;
                float dist = Vector3.Distance(current.transform.position, target.transform.position);
                if (dist <= spacing * 1.1f)
                {
                    if (!target.IsBlocked) current.ConnectedIds.Add(target.ID);
                }
            }
        }
    }
}