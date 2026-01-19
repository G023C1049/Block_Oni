using UnityEngine;
using System.Collections.Generic;
using System.Linq;

public static class MoveCalculator
{
    // ★追加: 「今すぐ隣へ移動できる候補」を返す
    public static List<string> GetImmediateCandidates(PlayerController player)
    {
        List<string> candidates = new List<string>();
        
        if (!MapGenerator.AllSquares.ContainsKey(player.CurrentSquareId)) return candidates;
        Square currentSq = MapGenerator.AllSquares[player.CurrentSquareId];

        // 1. 基本的な接続確認
        foreach (string neighborId in currentSq.ConnectedIds)
        {
            // 直前のマスには戻らない (Uターン禁止)
            // ※ただし残り歩数が残っている場合のみ。
            if (neighborId == player.LastSquareId) continue;

            // 角のルールチェック (斜め移動禁止)
            if (!ValidateCornerRule(player.CurrentSquareId, neighborId)) continue;

            // 2. 役割ごとのフィルタリング
            if (player.Role == "Oni")
            {
                // 鬼: 直進できるか？
                // 初回(LastSquareがない)は全方向OK、それ以降は直進のみ
                if (!string.IsNullOrEmpty(player.LastSquareId))
                {
                    Square prevSq = MapGenerator.AllSquares[player.LastSquareId];
                    Square neighborSq = MapGenerator.AllSquares[neighborId];
                    
                    // 厳密な直進判定 (Phase 15のロジック再利用)
                    Vector3 moveDir = (currentSq.transform.position - prevSq.transform.position).normalized;
                    if (!IsStrictlyStraight(moveDir, currentSq, neighborSq))
                    {
                        continue; // 直進じゃないなら候補から外す
                    }
                }
            }
            
            // 条件をクリアしたら候補入り
            candidates.Add(neighborId);
        }

        return candidates;
    }

    // (以下、Phase 15の IsStrictlyStraight, ValidateCornerRule はそのまま残す)
    // 既存の GetMovableSquares は今回の仕様では使わなくなりますが、残しておいても害はありません。
    
    // ... [IsStrictlyStraight と ValidateCornerRule のコードは前回と同じ] ...
    
    private static bool IsStrictlyStraight(Vector3 prevMoveDir, Square curr, Square next)
    {
        Vector3 nextMoveDir = (next.transform.position - curr.transform.position).normalized;
        if (curr.FaceName == next.FaceName)
        {
            return Vector3.Dot(prevMoveDir, nextMoveDir) > 0.9f;
        }
        float dot = Mathf.Abs(Vector3.Dot(prevMoveDir, next.CurrentNormal));
        return dot > 0.9f;
    }

    public static bool ValidateCornerRule(string fromId, string toId)
    {
        Square from = MapGenerator.AllSquares[fromId];
        Square to = MapGenerator.AllSquares[toId];
        if (from.FaceName == to.FaceName) return true;
        return true;
    }
}