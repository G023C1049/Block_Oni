using UnityEngine;
using System.Collections.Generic;
using DG.Tweening; // 回転アニメーション用に追加

public class MapGenerator : MonoBehaviour
{
    public GameObject cubePrefab;
    public float spacing = 1.1f;
    public static Dictionary<string, Square> AllSquares = new Dictionary<string, Square>();

    // ★追加: マップ全体を回すための親ピボット
    public Transform MapPivot;

    void Awake()
    {
        GenerateMap();
    }

    public void GenerateMap()
    {
        // 既存削除（MapPivotがある場合はその中身を消す）
        if (MapPivot != null)
        {
            foreach (Transform child in MapPivot) Destroy(child.gameObject);
        }
        else
        {
            // なければ作る
            GameObject pivotObj = new GameObject("MapPivot");
            pivotObj.transform.parent = this.transform;
            pivotObj.transform.localPosition = Vector3.zero; // 中心
            MapPivot = pivotObj.transform;
        }
        
        AllSquares.Clear();

        int blockLayerIndex = LayerMask.NameToLayer("Block");
        int size = 5;

        // 重心のズレ補正（0~4の中心は2.0）
        float offset = (size - 1) * spacing * 0.5f;

        for (int x = 0; x < size; x++)
        {
            for (int y = 0; y < size; y++)
            {
                for (int z = 0; z < size; z++)
                {
                    string face = GetFaceName(x, y, z, size);
                    if (face == "Inner") continue;

                    // MapPivotの子として生成
                    GameObject obj = Instantiate(cubePrefab, MapPivot);
                    
                    // 中心を(0,0,0)に合わせるための座標計算
                    obj.transform.localPosition = new Vector3(
                        x * spacing - offset, 
                        y * spacing - offset, 
                        z * spacing - offset
                    );
                    
                    obj.name = $"Cube_{x}_{y}_{z}";

                    if (blockLayerIndex != -1) obj.layer = blockLayerIndex;

                    Square sq = obj.GetComponent<Square>();
                    if (sq == null) sq = obj.AddComponent<Square>();

                    // ID設定など（変更なし）
                    sq.FaceName = face;
                    sq.ID = $"{face}_{x}_{z}";
                    
                    if (face == "Top" || face == "Bottom")
                    {
                        sq.ID = $"{face}_{x}_{z}";
                        sq.LocalCoordinates = new Vector2Int(x + 1, z + 1);
                    }
                    else if (face == "Front" || face == "Back")
                    {
                        sq.ID = $"{face}_{x}_{y}";
                        sq.LocalCoordinates = new Vector2Int(x + 1, y + 1);
                    }
                    else if (face == "Left" || face == "Right")
                    {
                        sq.ID = $"{face}_{z}_{y}";
                        sq.LocalCoordinates = new Vector2Int(z + 1, y + 1);
                    }

                    sq.IsBlocked = (face == "Bottom"); 
                    sq.SetupNormal();

                    if (!AllSquares.ContainsKey(sq.ID)) AllSquares.Add(sq.ID, sq);
                    else sq.ID += "_dup";
                }
            }
        }
        ConnectNeighbors();
        Debug.Log($"マップ生成完了: {AllSquares.Count}個");
    }

    // ★追加: ステージ回転メソッド
    public void RotateStage(Vector3 axis, float angle, float duration)
    {
        if (MapPivot == null) return;
        // DOTweenで回転
        MapPivot.DORotate(axis * angle, duration, RotateMode.WorldAxisAdd)
            .SetEase(Ease.InOutQuad);
    }

    // (以下、GetFaceName, ConnectNeighbors は変更なし)
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