/**
*	ケースコメントのトリガ
*/
trigger CaseCommentTrigger on CaseComment (after insert) {
    // トリガーハンドラーをインスタンス化
    LINE_CaseCommentTriggerHandler handler = new LINE_CaseCommentTriggerHandler();

    /**
    *	isAfter
    */
    if( trigger.isAfter ){
        if( trigger.isInsert ){
            handler.onAfterInsert(trigger.new);
        }
    }
}