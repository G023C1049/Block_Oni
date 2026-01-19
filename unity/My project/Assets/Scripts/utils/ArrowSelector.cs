using UnityEngine;
using System;
using DG.Tweening;

public class ArrowSelector : MonoBehaviour
{
    private string targetSquareId;
    private Action<string> onClickAction;

    public void Setup(string targetId, Vector3 direction, Action<string> onClick)
    {
        this.targetSquareId = targetId;
        this.onClickAction = onClick;

        // 見た目: 進行方向を向く
        transform.forward = direction;
        
        // アニメーション: ふわふわ動く
        transform.DOMove(transform.position + direction * 0.3f, 0.6f)
            .SetLoops(-1, LoopType.Yoyo)
            .SetEase(Ease.InOutSine);
    }

    void OnMouseDown()
    {
        // クリックされたら登録された処理を実行
        onClickAction?.Invoke(targetSquareId);
    }
}