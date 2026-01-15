using UnityEngine;
using DG.Tweening; 

public class PlayerController : MonoBehaviour
{
    public string PlayerId;
    public string Role;

    // ★エラー修正: GameManagerが呼び出せるようにSetupを復活させました
    public void Setup(string id, string role)
    {
        this.PlayerId = id;
        this.Role = role;
    }

    // 引数の型が違う場合用（念のため）
    public void Setup(string id, int index)
    {
        this.PlayerId = id;
    }

    // 指定した座標へジャンプ移動する
    public void MoveToSquare(Vector3 targetPos)
    {
        // ブロックの上に乗るようY軸調整
        Vector3 goal = targetPos + Vector3.up * 1.0f;

        // ジャンプアニメーション
        transform.DOJump(goal, 1.0f, 1, 0.5f).SetEase(Ease.OutQuad);
    }
}