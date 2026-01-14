using UnityEngine;
using System.Collections.Generic;

public class MapGenerator : MonoBehaviour
{
    public GameObject cubePrefab; // 四角いブロックのプレハブ
    public float spacing = 1.1f;  // ブロックの間隔

    public static Dictionary<string, Square> AllSquares = new Dictionary<string, Square>();

    void Start()
    {
        GenerateMap();
    }

    public void GenerateMap()
    {
        foreach (Transform child in transform) {
            Destroy(child.gameObject);
        }
        AllSquares.Clear();

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

                    // ★ここを修正しました★
                    Square sq = obj.GetComponent<Square>();
                    if (sq == null) sq = obj.AddComponent<Square>();
                    
                    sq.ID = $"{face}_{x}_{z}";
                    if (face == "Front" || face == "Back") sq.ID = $"{face}_{x}_{y}";
                    if (face == "Left" || face == "Right") sq.ID = $"{face}_{z}_{y}";
                    
                    sq.FaceName = face;
                    sq.IsBlocked = (face == "Bottom");

                    if (!AllSquares.ContainsKey(sq.ID))
                    {
                        AllSquares.Add(sq.ID, sq);
                    }
                    else
                    {
                        sq.ID += "_dup";
                    }
                }
            }
        }
        Debug.Log($"マップ生成完了: {AllSquares.Count}個のブロックを作成");
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
}