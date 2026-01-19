using UnityEngine;
using System.Collections.Generic;

public static class MoveCalculator
{
    // 「今すぐ隣へ移動できる候補」を返す
    public static List<string> GetImmediateCandidates(PlayerController player)
    {
        List<string> candidates = new List<string>();
        
        if (!MapGenerator.AllSquares.ContainsKey(player.CurrentSquareId)) return candidates;
        Square currentSq = MapGenerator.AllSquares[player.CurrentSquareId];

        foreach (string neighborId in currentSq.ConnectedIds)
        {
            // 1. Uターン禁止
            if (neighborId == player.LastSquareId) continue;

            Square neighborSq = MapGenerator.AllSquares[neighborId];

            // 2. 役割ごとの移動制限
            if (player.Role == "Oni")
            {
                // 【修正】距離チェック + 「軸共有チェック」で厳密に十字のみ許可する
                
                // A. 距離チェック (従来通り)
                float dist = Vector3.Distance(currentSq.transform.position, neighborSq.transform.position);
                if (dist > 1.2f) continue; // 平面の斜め(1.41)を弾く

                // B. ★追加: 軸共有チェック (角の斜め移動を弾く)
                // 十字移動(面またぎ含む)なら、X, Y, Z のうち少なくとも1つは
                // ほぼ同じ値になるはずである。
                // (例: TopからFrontへ降りる時、X座標は変わらない)
                // 逆に、X, Y, Z 全てが大きく変わっているなら、それは「角の斜め向こう」への移動である。

                Vector3 p1 = currentSq.transform.position;
                Vector3 p2 = neighborSq.transform.position;
                float diffX = Mathf.Abs(p1.x - p2.x);
                float diffY = Mathf.Abs(p1.y - p2.y);
                float diffZ = Mathf.Abs(p1.z - p2.z);

                // 許容誤差
                float epsilon = 0.1f;

                // 「どれか1つの軸が一致しているか？」
                bool sharesAxis = (diffX < epsilon) || (diffY < epsilon) || (diffZ < epsilon);

                if (!sharesAxis)
                {
                    // 全軸がズレている = 立体的な斜め移動なのでNG
                    continue;
                }
            }
            
            // 逃走者は制限なし

            candidates.Add(neighborId);
        }

        return candidates;
    }
}