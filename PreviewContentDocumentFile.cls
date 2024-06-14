public with sharing class PreviewContentDocumentFile {

    public Id id {get;set;}
    public String contentDocumentBase64 {get;set;}

    public PreviewContentDocumentFile(){
        id = apexpages.currentpage().getparameters().get('id');
        ContentVersion cv = [SELECT Id, VersionData, ContentDocumentId FROM ContentVersion WHERE Id = :id LIMIT 1];
        contentDocumentBase64 = EncodingUtil.Base64Encode(cv.VersionData);
    }
}