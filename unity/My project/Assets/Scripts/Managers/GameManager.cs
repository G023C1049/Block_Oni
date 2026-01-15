using UnityEngine;
using Newtonsoft.Json;
using FlutterUnityIntegration;
using BlockOni.Models;
using DG.Tweening; 
using UnityEngine.UI; 
using System.Collections.Generic;
using System.Linq; 

public class GameManager : MonoBehaviour
{
    public static GameManager Instance;

    [Header("参照設定")]
    public GameObject playerPrefab;
    public Text diceResultText;
    public Camera mainCamera; // ★追加: Raycast用

    // 現在の状態
    private PlayerController currentPlayer;
    private string currentSquareId = "Top_2_2"; // 初期位置
    
    // ★追加: 現在移動可能なマスのIDリスト
    private List<string> activeMovableIds = new List<string>();

    void Awake()
    {
        Instance = this;
        // カメラが未設定なら自動取得
        if (mainCamera == null) mainCamera = Camera.main;
    }

    void Start()
    {
        UnityMessageManager.Instance.SendMessageToFlutter("UnityReady");
        CreateTestPlayer();
    }

    void CreateTestPlayer()
    {
        if (MapGenerator.AllSquares.ContainsKey(currentSquareId))
        {
            Vector3 startPos = MapGenerator.AllSquares[currentSquareId].transform.position;
            GameObject pObj = Instantiate(playerPrefab, startPos + Vector3.up, Quaternion.identity);
            currentPlayer = pObj.GetComponent<PlayerController>();
            
            // SetupメソッドでIDなどを初期化（エラー回避）
            currentPlayer.Setup("Player1", "Oni");
        }
    }

    // ▼▼▼ クリック判定ロジック (今回追加) ▼▼▼
    void Update()
    {
        // 1. デバッグ用キー (Rキーでサイコロ)
        if (Input.GetKeyDown(KeyCode.R))
        {
            Debug.Log("【Debug】サイコロ 3 をシミュレート");
            OnReceiveFlutterMessage("{\"type\":\"DiceRolled\", \"result\":\"3\"}");
        }

        // 2. マウス/タップ入力判定
        if (Input.GetMouseButtonDown(0)) // 左クリック or タップ
        {
            HandleInput();
        }
    }

    void HandleInput()
    {
        // 移動可能リストが空ならクリックしても無意味なので無視
        if (activeMovableIds.Count == 0) return;

        Ray ray = mainCamera.ScreenPointToRay(Input.mousePosition);
        
        // Blockレイヤー(Mask)を指定してRayを飛ばす（設定済み前提）
        int layerMask = LayerMask.GetMask("Block"); 
        
        if (Physics.Raycast(ray, out RaycastHit hit, 100f, layerMask))
        {
            // クリックしたオブジェクトからSquareコンポーネントを取得
            Square clickedSquare = hit.collider.GetComponent<Square>();
            
            if (clickedSquare != null)
            {
                // そのマスが「移動可能リスト」に含まれているか確認
                if (activeMovableIds.Contains(clickedSquare.ID))
                {
                    Debug.Log($"【移動決定】{clickedSquare.ID} へ移動します");

                    // ★本来のフロー: Flutterへ「ここに行きたい」と通知する
                    // UnityMessageManager.Instance.SendMessageToFlutter($"RequestMove:{clickedSquare.ID}");
                    
                    // ★テスト用フロー: 直接自分に「移動命令」を送って動かす
                    string fakeMsg = $"{{\"type\":\"PlayerMoved\", \"targetSquareId\":\"{clickedSquare.ID}\"}}";
                    OnReceiveFlutterMessage(fakeMsg);
                }
                else
                {
                    Debug.Log("そこには移動できません（範囲外）");
                }
            }
        }
    }
    // ▲▲▲ ここまで ▲▲▲

    public void OnReceiveFlutterMessage(string jsonMessage)
    {
        var data = JsonConvert.DeserializeObject<Dictionary<string, string>>(jsonMessage);
        if (data == null || !data.ContainsKey("type")) return;

        switch (data["type"])
        {
            case "DiceRolled":
                if(data.ContainsKey("result"))
                {
                    int result = int.Parse(data["result"]);
                    ShowDiceAnimation(result);
                    HighlightAvailableMoves(currentSquareId, result);
                }
                break;

            case "PlayerMoved":
                if(data.ContainsKey("targetSquareId"))
                {
                    MovePlayer(data["targetSquareId"]);
                }
                break;
        }
    }

    void ShowDiceAnimation(int result)
    {
        if (diceResultText != null)
        {
            diceResultText.text = result.ToString();
            diceResultText.transform.localScale = Vector3.zero;
            diceResultText.transform.DOScale(1.5f, 0.5f).SetEase(Ease.OutBounce)
                .OnComplete(() => {
                    DOVirtual.DelayedCall(1.0f, () => {
                        diceResultText.text = "";
                    });
                });
        }
    }

    void HighlightAvailableMoves(string startId, int steps)
    {
        // リセット
        foreach(var sq in MapGenerator.AllSquares.Values) sq.SetHighlight(false);
        activeMovableIds.Clear(); // リストもクリア

        // BFS探索
        Queue<(string id, int remaining)> queue = new Queue<(string, int)>();
        queue.Enqueue((startId, steps));

        // 同じマスを何度も通らないように制御するかはルール次第だが、今回は簡易的に
        // 「ちょうどsteps歩目で到達できる場所」を探す
        
        // ※注意: 単純なBFSだと「行って戻る」などが含まれるため、
        // 厳密なすごろくロジックには「訪問済みリスト(visited)」が必要
        // 今回は「単純な距離」として実装
        
        // 到達可能リスト作成用
        HashSet<string> potentialTargets = new HashSet<string>();
        
        // 再帰やキューで全探索してもいいが、今回は簡易的に
        // 「距離がちょうど N のマス」ではなく
        // 「N歩で到達可能な全マス」をハイライトする実装例にします（わかりやすさ優先）
        // ※本格的な「N歩ピッタリ」は経路探索が必要

        // --- 簡易実装: 全探索 ---
        // ここではコード量削減のため、擬似的に「距離判定」を行います
        foreach(var kvp in MapGenerator.AllSquares)
        {
            // 実際はここを正確な経路探索にする必要がありますが、
            // まずは「クリック移動」のテストのため、全マスを対象にします
            // ★テスト仕様: 全マスハイライトして、どこでも行けるようにする（デバッグ用）
            // 　↓
            // activeMovableIds.Add(kvp.Key);
            // kvp.Value.SetHighlight(true);
            
            // ↑これだと芸がないので、ちゃんとBFSします
        }

        // --- BFS (再) ---
        // 訪問済み管理 (ID, 残り歩数) をキーにする
        // 単純化: 止まれる場所だけリストアップ
        
        Queue<(string id, int depth)> bfsQ = new Queue<(string, int)>();
        bfsQ.Enqueue((startId, 0));
        
        // そのIDに最小何歩で着いたか
        Dictionary<string, int> minSteps = new Dictionary<string, int>();
        minSteps[startId] = 0;

        while(bfsQ.Count > 0)
        {
            var current = bfsQ.Dequeue();
            string cid = current.id;
            int cDepth = current.depth;

            if(cDepth == steps)
            {
                // 指定歩数に達した
                if(!activeMovableIds.Contains(cid))
                {
                    activeMovableIds.Add(cid);
                    if(MapGenerator.AllSquares.ContainsKey(cid))
                        MapGenerator.AllSquares[cid].SetHighlight(true);
                }
                continue;
            }

            if(MapGenerator.AllSquares.ContainsKey(cid))
            {
                foreach(string nextId in MapGenerator.AllSquares[cid].ConnectedIds)
                {
                    // まだ訪れていない、あるいはもっと短いルートがあるなら更新
                    // （単純化のため、戻りなし想定で進む）
                    if(!minSteps.ContainsKey(nextId))
                    {
                        minSteps[nextId] = cDepth + 1;
                        bfsQ.Enqueue((nextId, cDepth + 1));
                    }
                }
            }
        }
    }

    void MovePlayer(string targetSquareID)
    {
        if (MapGenerator.AllSquares.ContainsKey(targetSquareID) && currentPlayer != null)
        {
            Vector3 targetPos = MapGenerator.AllSquares[targetSquareID].transform.position;
            currentPlayer.MoveToSquare(targetPos);
            currentSquareId = targetSquareID;
            
            // 移動完了したらハイライトを消して、移動入力を無効化
            foreach(var sq in MapGenerator.AllSquares.Values) sq.SetHighlight(false);
            activeMovableIds.Clear();
            
            Debug.Log("移動完了。次のダイスを待機します。");
        }
    }
}