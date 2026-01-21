using UnityEngine;
using DG.Tweening; 
using UnityEngine.UI;
using System.Collections.Generic;
using FlutterUnityIntegration; // 追加

public class PlayerController : MonoBehaviour
{
    public string PlayerId;
    public string Role;
    public string CurrentSquareId;
    public string LastSquareId;        
    public int RemainingSteps;        
    public int DiceBonus = 0;
    public int TotalStepsInTurn = 0;

    // ★追加: 元のスケールを保持
    private Vector3 originalScale;

    [Header("見た目・UI")]
    public Renderer meshRenderer; 
    public Text nameText; 
    public List<ItemType> OwnedItems = new List<ItemType>();

    void Start()
    {
        // ★追加: 開始時のスケールを保存
        originalScale = transform.localScale;
    }

    public void Setup(string id, string role, string startSquareId)
    {
        this.PlayerId = id;
        this.Role = role;
        this.CurrentSquareId = startSquareId;
        this.LastSquareId = ""; 
        this.RemainingSteps = 0;
        this.DiceBonus = 0;
        this.TotalStepsInTurn = 0;

        if (nameText != null)
        {
            nameText.text = id;
            nameText.color = (role == "Oni") ? Color.red : Color.cyan;
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

    public void MoveOneStep(string nextSquareId, System.Action onComplete)
    {
        if (!MapGenerator.AllSquares.ContainsKey(nextSquareId)) return;

        LastSquareId = CurrentSquareId;
        CurrentSquareId = nextSquareId;
        RemainingSteps--; 

        Square nextSq = MapGenerator.AllSquares[nextSquareId];
        Vector3 targetPos = nextSq.transform.position;
        Vector3 normal = nextSq.UpVector;

        float heightOffset = 0.6f; 
        Vector3 goal = targetPos + normal * heightOffset;

        Vector3 moveDir = (goal - transform.position).normalized;
        if (moveDir != Vector3.zero)
        {
            Quaternion targetRot = Quaternion.LookRotation(moveDir, normal);
            transform.DORotateQuaternion(targetRot, 0.2f);
        }

        transform.DOJump(goal, 0.5f, 1, 0.4f).SetEase(Ease.Linear)
            .OnComplete(() => {
                UpdateRotation(normal);
                CheckItemPickup();
                onComplete?.Invoke(); 
            });
    }

    public void ForceMoveTo(string targetSquareId, System.Action onComplete)
    {
        if (!MapGenerator.AllSquares.ContainsKey(targetSquareId)) return;

        LastSquareId = CurrentSquareId;
        CurrentSquareId = targetSquareId;
        
        Square nextSq = MapGenerator.AllSquares[targetSquareId];
        Vector3 targetPos = nextSq.transform.position;
        Vector3 normal = nextSq.UpVector;
        float heightOffset = 0.6f; 
        Vector3 goal = targetPos + normal * heightOffset;

        // ★修正: 1.0f ではなく originalScale に戻すことで巨大化を防ぐ
        transform.DOScale(Vector3.zero, 0.3f).OnComplete(() => {
            transform.position = goal;
            UpdateRotation(normal);
            transform.DOScale(originalScale, 0.3f).OnComplete(() => {
                onComplete?.Invoke();
            });
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
        if (MapGenerator.AllSquares.ContainsKey(CurrentSquareId))
        {
            Square currentSq = MapGenerator.AllSquares[CurrentSquareId];
            if (currentSq.CurrentItem != ItemType.None)
            {
                string itemTypeStr = currentSq.CurrentItem.ToString();
                Debug.Log($"<color=yellow>【ITEM】{PlayerId} は {itemTypeStr} を拾った！</color>");
                
                OwnedItems.Add(currentSq.CurrentItem);
                
                // ★追加: Flutterへアイテム取得を通知する
                // JSON: {"type": "ItemPickup", "playerId": "Oni1", "itemId": "SpeedUp"}
                string json = $"{{\"type\":\"ItemPickup\", \"playerId\":\"{PlayerId}\", \"itemId\":\"{itemTypeStr}\"}}";
                if (UnityMessageManager.Instance != null) UnityMessageManager.Instance.SendMessageToFlutter(json);

                currentSq.RemoveItem();
            }
        }
    }
}