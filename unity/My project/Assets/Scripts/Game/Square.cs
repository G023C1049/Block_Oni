using UnityEngine;
using System.Collections.Generic;

public enum ItemType { None, SpeedUp, Block }

public class Square : MonoBehaviour
{
    [Header("基本情報")]
    public string ID; 
    public string FaceName; 
    public Vector2Int LocalCoordinates; 

    // 初期設定時の法線（ローカル基準として保持）
    public Vector3 BaseUpVector; 

    // ★追加: 現在のワールド空間での法線を取得するプロパティ
    // MapPivot（親）が回転しても、それに応じて正しく変換された向きを返す
    public Vector3 CurrentNormal
    {
        get
        {
            if (transform.parent != null)
            {
                // 親（MapPivot）の回転を考慮して変換
                return transform.parent.TransformDirection(BaseUpVector);
            }
            return BaseUpVector;
        }
    }

    // 互換性のためのプロパティ（古いコードがUpVectorを参照している場合用）
    public Vector3 UpVector => CurrentNormal;

    [Header("状態")]
    public bool IsBlocked = false; 
    public ItemType CurrentItem = ItemType.None;
    
    private GameObject itemVisual; 
    public List<string> ConnectedIds = new List<string>();

    public void SetupNormal()
    {
        // 初期法線をセット（ローカル基準）
        switch (FaceName)
        {
            case "Top":    BaseUpVector = Vector3.up;    break;
            case "Bottom": BaseUpVector = Vector3.down;  break;
            case "Left":   BaseUpVector = Vector3.left;  break;
            case "Right":  BaseUpVector = Vector3.right; break;
            case "Front":  BaseUpVector = Vector3.forward; break;
            case "Back":   BaseUpVector = Vector3.back;    break;
            default:       BaseUpVector = Vector3.up;    break;
        }
    }

    public void SetHighlight(bool isActive)
    {
        var r = GetComponent<Renderer>();
        if (r != null) r.material.color = isActive ? Color.yellow : Color.white;
    }

    public void SpawnItem(ItemType type, GameObject prefab)
    {
        if (CurrentItem != ItemType.None) return;
        CurrentItem = type;
        if (prefab != null)
        {
            // CurrentNormalを使って配置
            itemVisual = Instantiate(prefab, transform.position + CurrentNormal * 0.8f, Quaternion.identity);
            itemVisual.transform.parent = this.transform;
        }
    }

    public void RemoveItem()
    {
        CurrentItem = ItemType.None;
        if (itemVisual != null)
        {
            Destroy(itemVisual);
            itemVisual = null;
        }
    }
}