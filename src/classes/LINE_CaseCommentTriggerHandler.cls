/**
*	ケースコメントのLINE用トリガハンドラー
*/
public with sharing class LINE_CaseCommentTriggerHandler {
    /**
     * After Insert時のハンドリング
     */
    public void onAfterInsert(CaseComment[] triggerNew) {
		Map<Id, String> ccMap = new Map<Id, String>();
		Set<Id> caseIds = new Set<Id>();
		for( CaseComment cc : triggerNew ){
			ccMap.put(cc.ParentId, cc.CommentBody);
			caseIds.add(cc.ParentId);
		}

		// 対象のケースのデータを取得し送信メッセージを作成
		// ※実際に利用する場合は、ガバナ制限やMessaging API側の制限を考慮する必要があるため、
		// ※このままでは動作しなくなることがあります
		if( caseIds.size() > 0 ){
			for( Case cs : [Select Id, LINE_UserID__c From Case Where Id In :caseIds Order By Id ASC]){
				// ケースIDがケースコメントのMapに含まれて入れば処理実行
				if( ccMap.containsKey(cs.Id) ){
					// 送信メッセージを作成
					Map<String, Object> msgMaps = new Map<String, Object>();
					msgMaps.put('to', cs.LINE_UserID__c);
					List<Object> msgObjs = new List<Object>();
					// 当該lineIdのメッセージを取得して規定の形で作成
					Map<String, Object> msgItemMaps = new Map<String, Object>();
					msgItemMaps.put('type', 'text');
					msgItemMaps.put('text', ccMap.get(cs.Id));
					msgObjs.add(msgItemMaps);
					msgMaps.put('messages', msgObjs);
					String jsonBody = Json.serialize(msgMaps);

					// ケースコメント送信
					System.enqueueJob(new LINE_QueueableCommon.QueueablePushMessage(jsonBody));
				}
			}
		}

    }
}