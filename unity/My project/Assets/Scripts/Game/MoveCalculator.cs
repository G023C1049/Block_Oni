using UnityEngine;
using System.Collections.Generic;

public static class MoveCalculator
{
    public static List<string> GetImmediateCandidates(PlayerController player)
    {
        List<string> candidates = new List<string>();
        
        if (!MapGenerator.AllSquares.ContainsKey(player.CurrentSquareId)) return candidates;
        Square currentSq = MapGenerator.AllSquares[player.CurrentSquareId];

        bool isRestrictedStraight = false;
        Square lastSq = null;

        // 鬼の直進縛りは「移動中」かつ「前回位置がある」場合のみ
        if (player.Role == "Oni" && player.RemainingSteps < player.TotalStepsInTurn)
        {
            if (!string.IsNullOrEmpty(player.LastSquareId) && MapGenerator.AllSquares.ContainsKey(player.LastSquareId))
            {
                lastSq = MapGenerator.AllSquares[player.LastSquareId];
                isRestrictedStraight = true;
            }
        }

        foreach (string neighborId in currentSq.ConnectedIds)
        {
            if (neighborId == player.LastSquareId) continue;

            Square neighborSq = MapGenerator.AllSquares[neighborId];

            // 底面への移動禁止
            if (Vector3.Dot(neighborSq.transform.up, Vector3.down) > 0.9f) continue;

            if (player.Role == "Oni")
            {
                if (!IsStraightMove(currentSq, neighborSq)) continue;

                if (isRestrictedStraight && lastSq != null)
                {
                    if (!IsContinuousStraight(lastSq, currentSq, neighborSq)) continue;
                }
            }
            
            candidates.Add(neighborId);
        }

        return candidates;
    }

    private static bool IsStraightMove(Square a, Square b)
    {
        float dist = Vector3.Distance(a.transform.position, b.transform.position);
        if (dist > 1.2f) return false;

        Vector3 p1 = a.transform.position;
        Vector3 p2 = b.transform.position;
        int diffCount = 0;
        float epsilon = 0.1f;
        if (Mathf.Abs(p1.x - p2.x) > epsilon) diffCount++;
        if (Mathf.Abs(p1.y - p2.y) > epsilon) diffCount++;
        if (Mathf.Abs(p1.z - p2.z) > epsilon) diffCount++;

        return diffCount <= 2;
    }

    private static bool IsContinuousStraight(Square last, Square current, Square next)
    {
        Vector3 v1 = (current.transform.position - last.transform.position).normalized;
        Vector3 v2 = (next.transform.position - current.transform.position).normalized;
        float dot = Vector3.Dot(v1, v2);

        if (dot > 0.9f) return true;

        float distLastToNext = Vector3.Distance(last.transform.position, next.transform.position);
        bool isFaceChange = (last.FaceName != current.FaceName) || (current.FaceName != next.FaceName);

        if (isFaceChange)
        {
            if (distLastToNext > 1.3f) return true;
        }

        return false;
    }
}