using UnityEngine;
using DG.Tweening; 
using UnityEngine.UI;
using System.Collections.Generic;

public class PlayerController : MonoBehaviour
{
    public string PlayerId;
    public string Role;
    public string CurrentSquareId;
    public string LastSquareId;       
    
    // ★重要: 残り歩数管理
    public int RemainingSteps;        
    public int DiceBonus = 0;

    [Header("見た目・UI")]
    public Renderer meshRenderer; 
    public Text nameText; 
    public List<ItemType> OwnedItems = new List<ItemType>();

    public void Setup(string id, string role, string startSquareId)
    {
        this.PlayerId = id;
        this.Role = role;
        this.CurrentSquareId = startSquareId;
        this.LastSquareId = ""; // 最初は履歴なし
        this.RemainingSteps = 0;
        this.DiceBonus = 0;

        if (nameText != null)
        {
            nameText.text = id;
            nameText.color = (role == "Oni") ? Color.red : Color.cyan;
        }
        if (MapGenerator.AllSquares.ContainsKey(startSquareId))
        {
            UpdateRotation(MapGenerator.AllSquares[startSquareId].UpVector);
        }
    }

    public void SetMaterial(Material mat)
    {
        if (meshRenderer != null) meshRenderer.material = mat;
        else 
        {
            var r = GetComponentInChildren<Renderer>();
            if(r != null) r.material = mat;
        }
    }

    // 1マス移動し、完了時に callback を呼ぶ
    public void MoveOneStep(string nextSquareId, System.Action onComplete)
    {
        if (!MapGenerator.AllSquares.ContainsKey(nextSquareId)) return;

        // 履歴更新
        LastSquareId = CurrentSquareId;
        CurrentSquareId = nextSquareId;
        RemainingSteps--; // 歩数を減らす

        Square nextSq = MapGenerator.AllSquares[nextSquareId];
        Vector3 targetPos = nextSq.transform.position;
        Vector3 normal = nextSq.UpVector;

        // ゴール計算
        Vector3 goal = targetPos + normal * 1.0f;

        // 回転演出
        Vector3 moveDir = (goal - transform.position).normalized;
        if (moveDir != Vector3.zero)
        {
            Quaternion targetRot = Quaternion.LookRotation(moveDir, normal);
            transform.DORotateQuaternion(targetRot, 0.2f);
        }

        // ジャンプ移動 (0.4秒でピョン)
        transform.DOJump(goal, 1.0f, 1, 0.4f).SetEase(Ease.Linear)
            .OnComplete(() => {
                UpdateRotation(normal);
                CheckItemPickup();
                onComplete?.Invoke(); // 完了通知
            });
    }

    void UpdateRotation(Vector3 upVector)
    {
        Vector3 forward = transform.forward;
        if (Mathf.Abs(Vector3.Dot(forward, upVector)) > 0.99f) forward = Vector3.forward; 
        Quaternion targetRot = Quaternion.LookRotation(forward, upVector);
        Quaternion upFix = Quaternion.FromToRotation(transform.up, upVector);
        transform.rotation = upFix * transform.rotation;
    }

    void CheckItemPickup()
    {
        // 最後の1歩（止まったマス）でのみアイテムを拾うのが普通だが、
        // 通過点でも拾える仕様ならここで処理。今回は「止まったとき」にするため
        // ここでは一旦ログだけ出すか、アイテム取得ロジックをGameManager側に寄せても良い。
        // いったん「通過でも拾う」仕様のままにしておきます。
        if (MapGenerator.AllSquares.ContainsKey(CurrentSquareId))
        {
            Square currentSq = MapGenerator.AllSquares[CurrentSquareId];
            if (currentSq.CurrentItem != ItemType.None)
            {
                Debug.Log($"<color=yellow>【ITEM】{PlayerId} は {currentSq.CurrentItem} を拾った！</color>");
                if (currentSq.CurrentItem == ItemType.SpeedUp) DiceBonus += 1;
                OwnedItems.Add(currentSq.CurrentItem);
                currentSq.RemoveItem();
            }
        }
    }
}