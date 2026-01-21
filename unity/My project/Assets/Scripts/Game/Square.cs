using UnityEngine;
using System.Collections.Generic;

// ★修正: AddDiceValueを削除し、3種類(SpeedUp, Teleport, StageRotate) + Block/None に整理
public enum ItemType { None, SpeedUp, Block, Teleport, StageRotate }

public class Square : MonoBehaviour
{
    [Header("基本情報")]
    public string ID; 
    public string FaceName; 
    public Vector2Int LocalCoordinates; 

    public Vector3 CurrentNormal => transform.up;
    public Vector3 UpVector => transform.up;

    [Header("状態")]
    public bool IsBlocked = false; 
    public ItemType CurrentItem = ItemType.None;
    
    private GameObject itemVisual; 
    public List<string> ConnectedIds = new List<string>();

    public void SetupNormal() { }

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
            // アイテム生成
            itemVisual = Instantiate(prefab, transform.position + CurrentNormal * 0.5f, Quaternion.identity);
            itemVisual.transform.parent = this.transform;
            itemVisual.transform.localRotation = Quaternion.identity;

            // サイズ補正
            itemVisual.transform.localScale = new Vector3(0.5f, 5.0f, 0.5f);

            // ★修正: 色分け処理 (AddDiceValue削除)
            Renderer r = itemVisual.GetComponent<Renderer>();
            if (r != null)
            {
                switch (type)
                {
                    case ItemType.SpeedUp:
                        r.material.color = Color.yellow; // 黄色
                        break;
                    case ItemType.Teleport:
                        r.material.color = Color.magenta; // 紫
                        break;
                    case ItemType.StageRotate:
                        r.material.color = new Color(1f, 0.5f, 0f); // オレンジ
                        break;
                    default:
                        r.material.color = Color.white;
                        break;
                }
            }
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