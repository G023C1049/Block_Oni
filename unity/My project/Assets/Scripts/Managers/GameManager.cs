using UnityEngine;
using UnityEngine.Scripting;
using Newtonsoft.Json;
using FlutterUnityIntegration;
using BlockOni.Models;
using DG.Tweening; 
using UnityEngine.UI; 
using System.Collections;
using System.Collections.Generic;
using System.Linq; 

public class GameManager : MonoBehaviour
{
    public static GameManager Instance;

    [Header("デバッグ設定")]
    public bool isDebugMode = true;

    [Header("参照設定")]
    public GameObject playerPrefab;
    public MapGenerator mapGenerator; 
    public Text diceResultText;
    public Text gameInfoText; 
    public Camera mainCamera;
    public GameObject resultPanel; 
    public Text resultText;

    [Header("マテリアル・アイテム")]
    public Material matOni;
    public Material matRunner;
    public GameObject itemPrefab;

    [Header("ゲーム状態")]
    public List<PlayerController> players = new List<PlayerController>();
    public int currentPlayerIndex = 0;
    public int turnCount = 1;
    public int MaxTurnLimit = 10;
    
    private PlayerController CurrentPlayer => (players.Count > 0 && currentPlayerIndex < players.Count) ? players[currentPlayerIndex] : null;
    private List<string> activeMovableIds = new List<string>(); 

    private bool isWaitingForDice = true;
    private bool isWaitingForDirection = false; 
    private bool isMoving = false; 
    private bool isGameEnded = false;
    private bool isEventPlaying = false; 
    
    // ゲーム開始制御用
    private bool isGameStarted = false;
    private string myPlayerName = "Guest";

    void Awake()
    {
        if (Instance == null) Instance = this;
        gameObject.name = "GameManager";

        if (mainCamera == null) mainCamera = Camera.main;
        if (mapGenerator == null) mapGenerator = FindObjectOfType<MapGenerator>();
    }

    void Start()
    {
        // Flutterへ「準備完了」を通知
        SendToFlutter("GameReady", new Dictionary<string, string>());

        // エディタ実行時は即座に開始（デバッグ用）
        if (Application.isEditor && isDebugMode) {
            DOVirtual.DelayedCall(0.1f, InitializeGame);
        }
    }

    public void OnReceiveFlutterMessage(string message)
    {
        Debug.Log("Unity received: " + message); 
        try {
            var data = JsonConvert.DeserializeObject<Dictionary<string, string>>(message);
            if (data != null && data.ContainsKey("type")) {
                string type = data["type"];
                
                if (type == "StartGame") {
                    if (data.ContainsKey("userName")) {
                        myPlayerName = data["userName"];
                    }
                    
                    if (!isGameStarted) {
                        isGameStarted = true;
                        DOVirtual.DelayedCall(0.1f, InitializeGame);
                    } else {
                        // 既に開始済みの場合は名前だけ更新
                        var userPlayer = players.FirstOrDefault(p => p.PlayerName == myPlayerName || p.PlayerName == "Guest");
                        if (userPlayer != null) {
                            userPlayer.PlayerName = myPlayerName;
                            userPlayer.UpdateNameDisplay();
                        }
                    }
                }
                else if (type == "DiceRolled") {
                    if(data.ContainsKey("result")) ReceiveDiceResult(int.Parse(data["result"]));
                }
                else if (type == "UseItem") {
                    if(data.ContainsKey("itemId")) ActivateItem(data["itemId"]);
                }
            }
        } catch (System.Exception e) {
            Debug.LogError("Error parsing Flutter message: " + e.Message);
        }
    }

    void InitializeGame()
    {
        isGameStarted = true;

        foreach(var p in players) if(p != null) Destroy(p.gameObject);
        players.Clear();

        var camController = mainCamera.GetComponent<CameraController>();
        if (camController != null && mapGenerator != null && mapGenerator.MapPivot != null) 
            camController.SetTarget(mapGenerator.MapPivot);

        // 4つのスポーン設定
        var slots = new List<(string id, string role, string pos, Material mat)> {
            ("Runner", "Runner", "Top_2_2", matRunner),
            ("Oni1",   "Oni",    "Top_0_0", matOni),
            ("Oni2",   "Oni",    "Top_4_0", matOni),
            ("Oni3",   "Oni",    "Top_0_4", matOni)
        };

        // 0~3の中からランダムに1つ選び、それを「ユーザー(自分)」とする
        int userIndex = Random.Range(0, 4);

        for (int i = 0; i < slots.Count; i++)
        {
            var slot = slots[i];
            
            // 選ばれたインデックスならユーザー名、それ以外はCPU名
            bool isMe = (i == userIndex);
            string assignedName = isMe ? myPlayerName : $"CPU {i}";
            
            SpawnPlayer(slot.id, slot.role, slot.pos, slot.mat, assignedName);

            // ★追加: 自分の役職が決まったらFlutterへ通知する
            if (isMe)
            {
                SendToFlutter("RoleAssigned", new Dictionary<string, string>{
                    {"role", slot.role} // "Oni" or "Runner"
                });
            }
        }

        if (isDebugMode) SpawnRandomItems(5);
        if (resultPanel != null) resultPanel.SetActive(false);
        isGameEnded = false;
        isEventPlaying = false;

        currentPlayerIndex = 0;
        turnCount = 1;
        isWaitingForDice = true;
        isWaitingForDirection = false;
        isMoving = false;

        if (CurrentPlayer != null) {
            UpdateGameInfoUI();
            SendTurnChangeToFlutter(); 
            if(isDebugMode) Debug.Log($"ゲーム開始: 第{turnCount}ターン / 手番: {CurrentPlayer.PlayerId}");
        }
    }

    void Update()
    {
        if (isGameEnded || isEventPlaying) return; 

        if (isDebugMode && Input.GetKeyDown(KeyCode.R))
        {
            if (CurrentPlayer != null && CurrentPlayer.RemainingSteps <= 0) ReceiveDiceResult(Random.Range(1, 7));
        }

        if (Input.GetMouseButtonDown(0)) HandleClickInteraction();
    }

    // ... (Dice, Move, Item 関連のメソッドは変更なしのため省略可能ですが、全文記述します) ...

    void ReceiveDiceResult(int baseResult)
    {
        if (CurrentPlayer == null) return;
        Debug.Log($"ReceiveDiceResult called: base={baseResult}");
        try
        {
            int bonus = CurrentPlayer.DiceBonus;
            int finalResult = baseResult + bonus;

            string json = $"{{\"type\":\"DiceCalculated\", \"base\":\"{baseResult}\", \"bonus\":\"{bonus}\", \"total\":\"{finalResult}\"}}";
            SendToFlutterJson(json);

            CurrentPlayer.DiceBonus = 0;
            UpdateGameInfoUI();
            OnDiceRolled(finalResult);
        }
        catch (System.Exception e)
        {
            Debug.LogError($"ReceiveDiceResult Error: {e.Message}");
        }
    }

    void OnDiceRolled(int result)
    {
        ShowDiceAnimation(result);
        if (CurrentPlayer != null) {
            CurrentPlayer.RemainingSteps = result;
            CurrentPlayer.TotalStepsInTurn = result; 
        }
        isWaitingForDice = false; 
        ProcessNextStep();
    }

    void ProcessNextStep()
    {
        if (CurrentPlayer == null) return;

        if (CurrentPlayer.RemainingSteps <= 0)
        {
            Debug.Log("移動終了");
            DOVirtual.DelayedCall(0.5f, CheckWinCondition);
            return;
        }

        List<string> candidates = MoveCalculator.GetImmediateCandidates(CurrentPlayer);
        foreach(var sq in MapGenerator.AllSquares.Values) sq.SetHighlight(false);
        activeMovableIds.Clear();

        if (candidates.Count == 0)
        {
            Debug.Log("行き止まり！");
            CurrentPlayer.RemainingSteps = 0;
            CheckWinCondition();
        }
        else if (candidates.Count == 1)
        {
            isWaitingForDirection = true;
            activeMovableIds = candidates;
            if(MapGenerator.AllSquares.ContainsKey(candidates[0]))
                MapGenerator.AllSquares[candidates[0]].SetHighlight(true);
        }
        else
        {
            Debug.Log($"移動先を選択してください (残り{CurrentPlayer.RemainingSteps}歩)");
            isWaitingForDirection = true;
            activeMovableIds = candidates;
            foreach (string id in candidates)
            {
                if(MapGenerator.AllSquares.ContainsKey(id))
                    MapGenerator.AllSquares[id].SetHighlight(true);
            }
        }
    }

    void ExecuteOneStep(string targetId)
    {
        if (CurrentPlayer == null) return;
        isWaitingForDirection = false;
        foreach(var sq in MapGenerator.AllSquares.Values) sq.SetHighlight(false);
        activeMovableIds.Clear();

        CurrentPlayer.MoveOneStep(targetId, () => 
        {
            UpdateGameInfoUI();
            ProcessNextStep();
        });
    }

    void HandleClickInteraction()
    {
        if (isGameEnded || isEventPlaying || isMoving) return;
        if (!isWaitingForDirection) return;

        Ray ray = mainCamera.ScreenPointToRay(Input.mousePosition);
        int layerMask = LayerMask.GetMask("Default", "Block"); 
        if (layerMask == 0) layerMask = Physics.DefaultRaycastLayers;

        if (Physics.Raycast(ray, out RaycastHit hit, 100f, layerMask))
        {
            GameObject hitObj = hit.collider.gameObject;
            Square clickedSquare = hitObj.GetComponent<Square>();
            if (clickedSquare == null) return;

            if (activeMovableIds.Contains(clickedSquare.ID))
            {
                hitObj.transform.DOPunchScale(Vector3.one * 0.2f, 0.2f, 10, 1);
                ExecuteOneStep(clickedSquare.ID);
            }
        }
    }
    
    public void ActivateItem(string itemType)
    {
        if (isGameEnded || isEventPlaying || CurrentPlayer == null) return;
        Debug.Log($"アイテム使用: {itemType}");

        switch(itemType)
        {
            case "Teleport":
                var validCandidates = MapGenerator.AllSquares.Values
                    .Where(sq => Vector3.Dot(sq.transform.up, Vector3.down) < 0.5f) 
                    .Select(sq => sq.ID)
                    .ToList();

                if (validCandidates.Count > 0)
                {
                    string randomId = validCandidates[Random.Range(0, validCandidates.Count)];
                    CurrentPlayer.ForceMoveTo(randomId, () => {
                        CheckWinCondition();
                    });
                }
                break;

            case "StageRotate":
                StartCoroutine(RotateStageEvent(1.0f));
                break;
            
            case "SpeedUp":
                if (!isWaitingForDice) return; 
                CurrentPlayer.DiceBonus += 2;
                UpdateGameInfoUI();
                break;
        }
    }

    void SpawnRandomItems(int count)
    {
        if (itemPrefab == null) return;
        var availableSquares = MapGenerator.AllSquares.Values
            .Where(sq => sq.CurrentItem == ItemType.None)
            .ToList();
        if (count > availableSquares.Count) count = availableSquares.Count;

        List<ItemType> allTypes = new List<ItemType> { 
            ItemType.SpeedUp, ItemType.Teleport, ItemType.StageRotate 
        };

        int spawnedCount = 0;
        while (spawnedCount < count && availableSquares.Count > 0)
        {
            ItemType nextType;
            if (spawnedCount < allTypes.Count) nextType = allTypes[spawnedCount];
            else nextType = allTypes[Random.Range(0, allTypes.Count)];

            int targetIndex = Random.Range(0, availableSquares.Count);
            availableSquares[targetIndex].SpawnItem(nextType, itemPrefab);
            availableSquares.RemoveAt(targetIndex);
            spawnedCount++;
        }
    }

    void SpawnPlayer(string id, string role, string startSquareId, Material mat, string playerName)
    {
        if (MapGenerator.AllSquares.ContainsKey(startSquareId))
        {
            Square sq = MapGenerator.AllSquares[startSquareId];
            Vector3 startPos = sq.transform.position;
            Vector3 normal = sq.UpVector;
            float heightOffset = 0.6f;
            GameObject pObj = Instantiate(playerPrefab, startPos + normal * heightOffset, Quaternion.identity);
            PlayerController pc = pObj.GetComponent<PlayerController>();
            
            pc.Setup(id, role, startSquareId);
            pc.PlayerName = playerName;
            pc.UpdateNameDisplay();

            if (pc.meshRenderer != null) pc.meshRenderer.material = mat;
            else if (pObj.GetComponent<Renderer>() != null) pObj.GetComponent<Renderer>().material = mat;

            players.Add(pc);
        }
    }

    void UpdateGameInfoUI() 
    {
        if (CurrentPlayer == null) return;
        if (gameInfoText != null)
        {
            string role = (CurrentPlayer.Role == "Oni") ? "鬼" : "逃走者";
            string steps = (CurrentPlayer.RemainingSteps > 0) ? $" 残り{CurrentPlayer.RemainingSteps}歩" : "";
            gameInfoText.text = $"Turn {turnCount}/{MaxTurnLimit}\nPlayer: {CurrentPlayer.PlayerId} ({role}){steps}";

            string statusMsg = $"Turn {turnCount} / 手番: {CurrentPlayer.PlayerName} ({role})";
            if (CurrentPlayer.RemainingSteps > 0) statusMsg += $" (残り{CurrentPlayer.RemainingSteps}歩)";
            
            string json = $"{{\"type\":\"StatusUpdate\", \"message\":\"{statusMsg}\"}}";
            SendToFlutterJson(json);
        }
    }

    void SendTurnChangeToFlutter()
    {
        if (CurrentPlayer == null) return;
        string json = $"{{\"type\":\"TurnChange\", \"playerId\":\"{CurrentPlayer.PlayerId}\"}}";
        SendToFlutterJson(json);
    }

    void SendToFlutter(string type, Dictionary<string, string> data)
    {
        data["type"] = type;
        string json = JsonConvert.SerializeObject(data);
        SendToFlutterJson(json);
    }

    void SendToFlutterJson(string json)
    {
        if (UnityMessageManager.Instance != null) UnityMessageManager.Instance.SendMessageToFlutter(json);
    }

    void ShowDiceAnimation(int result)
    {
        if (diceResultText != null)
        {
            diceResultText.text = result.ToString();
            diceResultText.transform.localScale = Vector3.zero;
            diceResultText.transform.DOScale(1.5f, 0.5f).SetEase(Ease.OutBounce)
                .OnComplete(() => {
                    DOVirtual.DelayedCall(0.5f, () => { diceResultText.text = ""; });
                });
        }
    }

    // ★修正: 勝敗判定と通知
    void CheckWinCondition()
    {
        var runner = players.FirstOrDefault(p => p.Role == "Runner");
        var onis = players.Where(p => p.Role == "Oni").ToList();
        if (runner == null) return;
        
        bool oniWin = false;
        foreach (var oni in onis)
        {
            if (oni.CurrentSquareId == runner.CurrentSquareId)
            {
                oniWin = true;
                break;
            }
        }
        
        if (oniWin) 
        {
            // 鬼チーム勝利
            ShowResult("ONI TEAM WIN!", "OniWin");
            return;
        }

        if (turnCount >= MaxTurnLimit && currentPlayerIndex == players.Count - 1)
        {
            // 時間切れで逃走者勝利
            ShowResult("RUNNER WINS! (Time Up)", "RunnerWin");
            return;
        }

        NextTurn();
    }

    // ★修正: 表示用メッセージと通信用コードを分離
    void ShowResult(string displayMessage, string resultCode)
    {
        isGameEnded = true;
        if (resultPanel != null && resultText != null)
        {
            resultPanel.SetActive(true);
            resultText.text = displayMessage;
            resultText.transform.localScale = Vector3.zero;
            resultText.transform.DOScale(1.0f, 0.5f).SetEase(Ease.OutBack);
        }
        
        // Flutterには識別コードを送る
        string json = $"{{\"type\":\"GameEnd\", \"result\":\"{resultCode}\"}}";
        SendToFlutterJson(json);
        Debug.Log($"<color=red>【GAME SET】{displayMessage} (Code: {resultCode})</color>");
    }

    void NextTurn()
    {
        if (isGameEnded) return;
        
        currentPlayerIndex = (currentPlayerIndex + 1) % players.Count;
        if (currentPlayerIndex == 0) turnCount++;
        
        if (CurrentPlayer != null) {
            CurrentPlayer.RemainingSteps = 0;
            isWaitingForDice = true; 
            isWaitingForDirection = false;
            
            UpdateGameInfoUI();
            SendTurnChangeToFlutter();

            if (currentPlayerIndex == 0 && turnCount > 1 && (turnCount - 1) % 4 == 0)
            {
                isWaitingForDice = false; 
                StartCoroutine(RotateStageEvent());
            }
        }
    }

    IEnumerator RotateStageEvent(float duration = 2.0f)
    {
        isEventPlaying = true;
        if (mapGenerator != null && mapGenerator.MapPivot != null)
        {
            foreach(var p in players) p.transform.SetParent(mapGenerator.MapPivot);
            
            Vector3 axis = (Random.value > 0.5f) ? Vector3.right : Vector3.forward;
            mapGenerator.RotateStage(axis, 90f, duration);
            yield return new WaitForSeconds(duration);
            
            foreach(var p in players) p.transform.SetParent(null);
            CheckAndTeleportBottomPlayers();
        }

        isEventPlaying = false;
        isWaitingForDice = true; 
        isWaitingForDirection = false;
        SendTurnChangeToFlutter();
    }

    void CheckAndTeleportBottomPlayers()
    {
        foreach(var p in players)
        {
            if(!MapGenerator.AllSquares.ContainsKey(p.CurrentSquareId)) continue;
            
            Square currentSq = MapGenerator.AllSquares[p.CurrentSquareId];
            if (Vector3.Dot(currentSq.transform.up, Vector3.down) > 0.9f)
            {
                Square targetSq = FindTopSquareAt(currentSq.transform.position.x, currentSq.transform.position.z);
                if (targetSq != null)
                {
                    p.CurrentSquareId = targetSq.ID;
                    p.transform.position = targetSq.transform.position + targetSq.UpVector * 0.6f;
                }
            }
        }
    }

    Square FindTopSquareAt(float worldX, float worldZ)
    {
        Square bestSq = null;
        float maxY = -999f;
        foreach(var sq in MapGenerator.AllSquares.Values)
        {
            if (Mathf.Abs(sq.transform.position.x - worldX) < 0.2f && Mathf.Abs(sq.transform.position.z - worldZ) < 0.2f)
            {
                if (sq.transform.position.y > maxY)
                {
                    maxY = sq.transform.position.y;
                    bestSq = sq;
                }
            }
        }
        return bestSq;
    }
}