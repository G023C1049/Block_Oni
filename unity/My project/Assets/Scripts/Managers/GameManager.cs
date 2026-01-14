using UnityEngine;
using Newtonsoft.Json;
using FlutterUnityIntegration;
using BlockOni.Models;
using DG.Tweening;
using UnityEngine.UI;
using System.Collections.Generic;

public class GameManager : MonoBehaviour
{
    public static GameManager Instance;

    [Header("参照設定")]
    public GameObject playerPrefab; // セットし忘れないように注意！
    public Text diceResultText;

    // 管理用リスト
    private Dictionary<string, PlayerController> activePlayers = new Dictionary<string, PlayerController>();

    void Awake()
    {
        Instance = this;
    }

    void Start()
    {
        UnityMessageManager.Instance.SendMessageToFlutter("UnityReady");
    }

    // ★追加: タップ操作の検知
    void Update()
    {
        // マウス左クリック (スマホならタップ)
        if (Input.GetMouseButtonDown(0))
        {
            HandleInput();
        }
    }

    void HandleInput()
    {
        Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);
        RaycastHit hit;

        if (Physics.Raycast(ray, out hit))
        {
            // クリックしたオブジェクトから Square コンポーネントを取得
            Square sq = hit.collider.GetComponent<Square>();
            if (sq != null)
            {
                Debug.Log($"[Unity] タップされたマス: {sq.ID}");
                
                // タップアニメーション（軽くへこむ）
                sq.transform.DOPunchScale(Vector3.one * -0.1f, 0.2f);

                // Flutterへ「このマスを選んだよ」と伝える
                // 実際は自分のターンかどうかの判定が必要ですが、まずは送るだけ
                var msg = new Dictionary<string, string>
                {
                    { "type", "SquareTapped" },
                    { "squareId", sq.ID }
                };
                UnityMessageManager.Instance.SendMessageToFlutter(JsonConvert.SerializeObject(msg));
            }
        }
    }

    public void OnReceiveFlutterMessage(string jsonMessage)
    {
        Debug.Log($"[Unity] 受信: {jsonMessage}");
        var data = JsonConvert.DeserializeObject<Dictionary<string, string>>(jsonMessage);
        if (data == null || !data.ContainsKey("type")) return;

        switch (data["type"])
        {
            case "GameStart":
                // ペイロードの中身が RoomData (membersリスト入り) と仮定
                if (data.ContainsKey("payload"))
                {
                    var room = JsonConvert.DeserializeObject<RoomData>(data["payload"]);
                    SpawnPlayers(room.members);
                }
                break;

            case "DiceRolled":
                if(data.ContainsKey("result")) ShowDiceAnimation(int.Parse(data["result"]));
                break;
            
            case "PlayerMoved":
                if(data.ContainsKey("playerId") && data.ContainsKey("targetSquareId"))
                    MovePlayer(data["playerId"], data["targetSquareId"]);
                break;
        }
    }

    // ★追加: プレイヤー生成処理
    void SpawnPlayers(List<PlayerData> members)
    {
        // 既存のプレイヤーがいれば削除
        foreach (var p in activePlayers.Values) Destroy(p.gameObject);
        activePlayers.Clear();

        foreach (var member in members)
        {
            // 初期位置のマスの座標を取得
            if (MapGenerator.AllSquares.TryGetValue(member.currentSquareId, out Square sq))
            {
                // 生成
                GameObject pObj = Instantiate(playerPrefab);
                pObj.transform.position = sq.transform.position + Vector3.up * 1.0f;
                
                // セットアップ
                PlayerController pc = pObj.GetComponent<PlayerController>();
                pc.Setup(member.id, member.role); // ここで色が変わる

                activePlayers.Add(member.id, pc);
            }
            else
            {
                Debug.LogError($"初期位置 {member.currentSquareId} が見つかりません！");
            }
        }
        Debug.Log($"{members.Count}人のプレイヤーを配置しました");
    }

    void ShowDiceAnimation(int result) { /* (前回のまま) */ }

    void MovePlayer(string playerId, string targetSquareID)
    {
        if (activePlayers.ContainsKey(playerId) && MapGenerator.AllSquares.ContainsKey(targetSquareID))
        {
            Vector3 targetPos = MapGenerator.AllSquares[targetSquareID].transform.position;
            activePlayers[playerId].MoveToSquare(targetPos);
        }
    }
}