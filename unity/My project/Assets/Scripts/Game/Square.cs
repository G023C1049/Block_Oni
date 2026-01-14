using UnityEngine;
using System.Collections.Generic;

public class Square : MonoBehaviour
{
    [Header("基本情報")]
    public string ID; // 例: Top_1_1
    public Vector2Int Coordinate; // 面の中での座標 (x, y)
    public string FaceName; // Top, Bottom, Front, Back, Left, Right

    [Header("状態")]
    public bool IsBlocked = false; // 通行不可フラグ

    // 隣接するマスのIDリスト
    public List<string> ConnectedIds = new List<string>();

    // マスの色を変える（デバッグ用・選択用）
    public void SetHighlight(bool isActive)
    {
        GetComponent<Renderer>().material.color = isActive ? Color.yellow : Color.white;
    }
}