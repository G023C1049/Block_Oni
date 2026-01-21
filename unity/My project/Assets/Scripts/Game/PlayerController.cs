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
        this.LastSquareId = ""; 
        this.RemainingSteps = 0;
        this.DiceBonus = 0;

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

        // ★高さ調整: パネル中心から0.6浮かす（表面に乗る）
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

    public void MoveToSquare(string nextSquareId, Vector3 targetPos)
    {
        Square nextSq = MapGenerator.AllSquares[nextSquareId];
        Vector3 normal = nextSq.UpVector;
        float heightOffset = 0.6f;
        Vector3 goal = targetPos + normal * heightOffset;

        transform.DOJump(goal, 0.5f, 1, 0.5f).SetEase(Ease.Linear)
             .OnComplete(() => UpdateRotation(normal));
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
                Debug.Log($"<color=yellow>【ITEM】{PlayerId} は {currentSq.CurrentItem} を拾った！</color>");
                if (currentSq.CurrentItem == ItemType.SpeedUp) DiceBonus += 1;
                OwnedItems.Add(currentSq.CurrentItem);
                currentSq.RemoveItem();
            }
        }
    }
}