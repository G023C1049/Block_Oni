using UnityEngine;
using System.Collections.Generic;

public enum ItemType { None, SpeedUp, Block }

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

            // ★修正: 親(パネル)がつぶれている分、子(アイテム)を引き伸ばして補正する
            // パネルのScaleは (1.0, 0.1, 1.0)
            // そのため、Y方向に 1/0.1 = 10倍 の補正をかけないと球体にならない
            
            // アイテム自体の見た目のサイズを 0.5 くらいにしたい場合
            // X: 0.5 / 1.0 = 0.5
            // Y: 0.5 / 0.1 = 5.0  <-- ここ重要
            // Z: 0.5 / 1.0 = 0.5
            itemVisual.transform.localScale = new Vector3(0.5f, 5.0f, 0.5f);
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