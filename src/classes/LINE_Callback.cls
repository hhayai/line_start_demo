/**
*	LINEからWebhookでメッセージを受け取るクラス
*/
@RestResource(urlMapping='/lineCallback')
global with sharing class LINE_Callback {
	/**
	*	POSTされたデータの処理
	*	@return Boolean
	*/
    @HttpPost
    global static Boolean doPost() {
        // LINE設定
        String LINE_AT_CH_ACCESS_TOKEN = 'xXMv8VCsK7Fcgng5dsT6KQUxxNqOkCrIf7+n500YYwe5z1kabWp4z+inWlkoT8nKTpGqJuaIveB5SvS/tLXiQMBg0fQM0bkaABDDChaS/priNiMmA77HFBNVU7oDrkkhv2ilw2LR9kd8r2fTX8LbogdB04t89/1O/w1cDnyilFU=';
        String LINE_GET_PROFILE_URI = 'https://api.line.me/v2/bot/profile/';

		/**
		*	POSTされたデータを展開
		*/
		RestRequest req = RestContext.request;
		Map<String, Object> callbackParams = (Map<String, Object>)JSON.deserializeUntyped(req.requestBody.ToString());
		List<Object> resultParams = (List<Object>)callbackParams.get('events');
		String replyToken;

        // eventsのデータを展開
        for( Object obj : resultParams ) {
            Map<String, Object> params = (Map<String, Object>)obj;
            // ReplyTokenを取得
            replyToken = (String)params.get('replyToken');
            String eventType = (String)params.get('type');
            Map<String, Object> sourceParams = (Map<String, Object>)params.get('source');
            // sourceのデータ
            String sourceType = (String)sourceParams.get('type');
            String userId = (String)sourceParams.get('userId');
            String groupId = (String)sourceParams.get('groupId');

            // プロフィールデータを取得
            String profileBody = exGetUserProfile(userId, LINE_AT_CH_ACCESS_TOKEN, LINE_GET_PROFILE_URI);
            Map<String, Object> profileParams = (Map<String, Object>)JSON.deserializeUntyped(profileBody);
            String displayName = (String)profileParams.get('displayName');

            // 存在チェック
            Integer cntChkQuery = [Select Count() From Contact Where LINE_UserID__c = :userId];
            Id conId = null;
            if( cntChkQuery > 0 ){
                // 履歴紐付け先のIDを取得
                Contact conData = [Select Id From Contact Where LINE_UserID__c = :userId Limit 1];
                conId = conData.Id;
            }

            /**
            *   followの時の処理
            */
            if( eventType == 'follow' ){
                sObject sObj;
                Contact ctData = new Contact();

                // 登録がない場合
                if( cntChkQuery == 0 ){
                    // 友達登録
                    Contact conData = new Contact();
                    conData.LastName = displayName;
                    conData.LINE_UserID__c = userId;
                    conData.LINE_IsFriend__c = true;
                    insert conData;

                // 登録がある場合
                }else{
                    Contact conData = [Select Id, LINE_IsFriend__c From Contact Where LINE_UserID__c = :userId Limit 1];
                    conData.LINE_IsFriend__c = true;

                    // 取引先責任者を更新
                    update conData;
                }

            /**
            *   unfollowの時の処理
            */
            }else if( eventType == 'unfollow' ){
                // 登録がない場合
                if( cntChkQuery == 0 ){
                    continue;

                // 登録がある場合
                }else{
                    // ブロックされたらメッセージは送れないのでDML処理のみ
                    Contact conData = [Select Id, LINE_IsFriend__c From Contact Where LINE_UserID__c = :userId Limit 1];
                    conData.LINE_IsFriend__c = false;
                    update conData;
                }

            /**
            *   messageの時の処理
            */
            }else if( eventType == 'message' ){
                // メッセージを取得
                Map<String, Object> msgParams = (Map<String, Object>)params.get('message');
                String msgTypeStr = (String)msgParams.get('type');

                // テキストの場合
                if( msgTypeStr == 'text' ){
					// LINEのユーザーIDと一致する取引先責任者のIDを取得
					Integer chkCnt = [Select Count() From Contact Where LINE_UserID__c = :userId];
					if( chkCnt > 0 ){
						Contact frdConData = [Select Id From Contact Where LINE_UserID__c = :userId Limit 1];

						// メッセージ取得
						String msgStr = (String)msgParams.get('text');

						// ケースを作成
						Case newCase = new Case();
						newCase.Subject = 'お問い合わせ';
						newCase.Description = msgStr;
						newCase.Status = 'New';
						newCase.Origin = 'Web';
						newCase.ContactId = frdConData.Id;
						insert newCase;

						// 返信メッセージを作成
						Map<String, Object> msgMaps = new Map<String, Object>();
						List<Object> msgObjs = new List<Object>();
						Map<String, Object> msgItemMaps = new Map<String, Object>();
						msgItemMaps.put('type', 'text');
						String retMsgStr = 'お問い合わせを受け付けました';
						msgItemMaps.put('text', retMsgStr);
						msgObjs.add(msgItemMaps);
						msgMaps.put('messages', msgObjs);
						msgMaps.put('replyToken', replyToken);
						String jsonBody = Json.serialize(msgMaps);

						// 登録完了メッセージを返信
						System.enqueueJob(new LINE_QueueableCommon.QueueableReplyMessage(jsonBody));
					}
                }
            }
        }
        return true;
    }

    /**
    *   友達のプロファイルデータを取得する処理
    */
    public static String exGetUserProfile(String userId, String LINE_AT_CH_ACCESS_TOKEN, String LINE_GET_PROFILE_URI){
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer '+ LINE_AT_CH_ACCESS_TOKEN);
        req.setEndpoint(LINE_GET_PROFILE_URI + userId);
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res.getBody();
    }
}