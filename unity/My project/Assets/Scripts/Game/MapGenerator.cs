using UnityEngine;
using System.Collections.Generic;
using DG.Tweening;

public class MapGenerator : MonoBehaviour
{
    [Header("設定")]
    public GameObject cubePrefab; // パネルのプレハブ
    public float spacing = 1.0f;  // マス目の間隔（1.0固定推奨）
    public int mapSize = 5;       // マップの一辺の数 (奇数推奨: 5)

    [Header("パネル設定")]
    // 1.0 x 1.0 の正方形で、厚みが0.1のパネル
    public Vector3 panelScale = new Vector3(1.0f, 0.1f, 1.0f); 

    public static Dictionary<string, Square> AllSquares = new Dictionary<string, Square>();
    public Transform MapPivot;

    void Awake()
    {
        GenerateMap();
    }

    public void GenerateMap()
    {
        // 親オブジェクトのリセット
        if (MapPivot != null)
        {
            foreach (Transform child in MapPivot) Destroy(child.gameObject);
        }
        else
        {
            GameObject pivotObj = new GameObject("MapPivot");
            pivotObj.transform.parent = this.transform;
            pivotObj.transform.localPosition = Vector3.zero;
            MapPivot = pivotObj.transform;
        }
        
        AllSquares.Clear();

        // --- 座標計算の準備 ---
        // マップ全体の物理的な半径（中心から表面までの距離）
        float mapRadius = (mapSize * spacing) / 2.0f;

        // パネルの中心座標を決めるためのオフセット
        float facePos = mapRadius - (panelScale.y / 2.0f);

        // --- 6つの面を独立して生成 ---
        GenerateFace("Top",    Vector3.up,      facePos);
        GenerateFace("Bottom", Vector3.down,    facePos);
        GenerateFace("Front",  Vector3.forward, facePos);
        GenerateFace("Back",   Vector3.back,    facePos);
        GenerateFace("Right",  Vector3.right,   facePos);
        GenerateFace("Left",   Vector3.left,    facePos);

        ConnectNeighbors();
        Debug.Log($"マップ生成完了: {AllSquares.Count}個 (6面独立生成方式)");
    }

    // 指定した面のパネルを一括生成するメソッド
    void GenerateFace(string faceName, Vector3 normal, float distFromCenter)
    {
        int blockLayerIndex = LayerMask.NameToLayer("Block");
        
        // 軸の定義
        for (int i = 0; i < mapSize; i++)
        {
            for (int j = 0; j < mapSize; j++)
            {
                // グリッド座標 (-2.0, -1.0, 0, 1.0, 2.0) のように中心0基準で計算
                float offset = (mapSize - 1) * spacing / 2.0f;
                float u = (i * spacing) - offset;
                float v = (j * spacing) - offset;

                Vector3 localPos = Vector3.zero;
                Vector2Int coord = Vector2Int.zero;
                string id = "";

                // 面ごとの座標変換
                if (faceName == "Top" || faceName == "Bottom")
                {
                    localPos = (normal * distFromCenter) + new Vector3(u, 0, v);
                    id = $"{faceName}_{i}_{j}";
                    coord = new Vector2Int(i + 1, j + 1);
                }
                else if (faceName == "Front" || faceName == "Back")
                {
                    localPos = (normal * distFromCenter) + new Vector3(u, v, 0);
                    id = $"{faceName}_{i}_{j}";
                    coord = new Vector2Int(i + 1, j + 1);
                }
                else if (faceName == "Right" || faceName == "Left")
                {
                    localPos = (normal * distFromCenter) + new Vector3(0, v, u);
                    id = $"{faceName}_{i}_{j}";
                    coord = new Vector2Int(i + 1, j + 1);
                }

                // 生成処理
                GameObject obj = Instantiate(cubePrefab, MapPivot);
                obj.name = $"Panel_{id}";
                obj.transform.localPosition = localPos;
                
                // 回転: 上方向(Y)を法線(Normal)に向ける
                obj.transform.rotation = Quaternion.FromToRotation(Vector3.up, normal);
                
                // スケール
                obj.transform.localScale = panelScale;

                // レイヤー
                if (blockLayerIndex != -1) obj.layer = blockLayerIndex;

                // Squareコンポーネント
                Square sq = obj.GetComponent<Square>();
                if (sq == null) sq = obj.AddComponent<Square>();

                sq.FaceName = faceName;
                sq.ID = id;
                sq.LocalCoordinates = coord;
                
                // ★修正: 生成時は「通行止め」にしない。
                // 実際に通れるかどうかは移動時に MoveCalculator で「今、下を向いているか」判定する。
                sq.IsBlocked = false; 

                sq.SetupNormal();

                if (!AllSquares.ContainsKey(sq.ID))
                {
                    AllSquares.Add(sq.ID, sq);
                }
            }
        }
    }

    // ステージ回転
    public void RotateStage(Vector3 axis, float angle, float duration)
    {
        if (MapPivot == null) return;
        MapPivot.DORotate(axis * angle, duration, RotateMode.WorldAxisAdd)
            .SetEase(Ease.InOutQuad);
    }

    // 隣接マスの接続
    void ConnectNeighbors()
    {
        float connectThreshold = spacing * 1.5f;

        foreach (var kvp in AllSquares)
        {
            Square current = kvp.Value;
            current.ConnectedIds.Clear();
            foreach (var targetKvp in AllSquares)
            {
                Square target = targetKvp.Value;
                if (current == target) continue;

                float dist = Vector3.Distance(current.transform.position, target.transform.position);
                if (dist <= connectThreshold)
                {
                    // ★修正: ここで IsBlocked をチェックせず、無条件でつなぐ。
                    // これで「元底面」だったマスへのリンクが保持される。
                    current.ConnectedIds.Add(target.ID);
                }
            }
        }
    }
}