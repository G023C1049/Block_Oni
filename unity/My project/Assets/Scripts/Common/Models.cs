using System.Collections.Generic;
using UnityEngine;
using Newtonsoft.Json;

namespace BlockOni.Models
{
    // サーバーとやり取りするJSONデータの型定義
    [System.Serializable]
    public class RoomData
    {
        public string id;
        public string status; // "waiting", "playing"
        public List<PlayerData> members;
    }

    [System.Serializable]
    public class PlayerData
    {
        public string id;
        public string name;
        public string role; // "Oni", "Runner"
        public string currentSquareId; // 現在のマスのID (例: "Top_2_2")
        public int positionIndex;
    }

    [System.Serializable]
    public class DiceResult
    {
        public string playerId;
        public int result; // 1~6
    }

    [System.Serializable]
    public class MoveResult
    {
        public string playerId;
        public string targetSquareId;
    }
}