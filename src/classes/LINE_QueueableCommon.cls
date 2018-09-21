/**
*	各種System.Queueable共通クラス
*/
global with sharing class LINE_QueueableCommon {
	/**
	*	非同期返信処理（Reply Message）
	*/
    global class QueueableReplyMessage implements System.Queueable, Database.AllowsCallouts{
		// LINE設定
		private String LINE_REPLY_MSG_URI = 'https://api.line.me/v2/bot/message/reply';
		private String LINE_AT_CH_ACCESS_TOKEN = 'xXMv8VCsK7Fcgng5dsT6KQUxxNqOkCrIf7+n500YYwe5z1kabWp4z+inWlkoT8nKTpGqJuaIveB5SvS/tLXiQMBg0fQM0bkaABDDChaS/priNiMmA77HFBNVU7oDrkkhv2ilw2LR9kd8r2fTX8LbogdB04t89/1O/w1cDnyilFU=';			// 自身の環境のアクセストークンを貼り付け
		// メッセージデータ
        String jsonBody;

        global QueueableReplyMessage(String jsonBody) {
            this.jsonBody= jsonBody;
        }

        global void execute(System.QueueableContext ctx) {
            // 送信データを作成して送信
            HttpRequest req = new HttpRequest();
			req.setHeader('Authorization', 'Bearer '+ LINE_AT_CH_ACCESS_TOKEN);
			req.setHeader('Content-Type', 'application/json');
			req.setEndpoint(LINE_REPLY_MSG_URI);
            req.setMethod('POST');
            req.setBody(jsonBody);
            Http http = new Http();
            HTTPResponse res = http.send(req);
        }
    }
}