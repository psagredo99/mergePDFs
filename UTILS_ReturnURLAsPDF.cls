/**
 * @description       : Mergear pdf con contentDocument ya existente mediante lib externa pdfLib
 * @author            : pablo.sagredo@pkf-attest.es
 * @group             : soporte Salesforce
 * @last modified on  : 06-12-2024
 * @last modified by  : pablo.sagredo@pkf-attest.es
**/
public with sharing class UTILS_ReturnURLAsPDF {

    /*Carga pdfs desde render de visual force page url incluye los parametros */
    @AuraEnabled
    public static String getPdfFileAsBase64String(String url) {

        System.debug('url: ' + url);
        

        PageReference pdfPage = new PageReference(url);
        String base64Pdf ='';
        if(!Test.isRunningTest()) 
        {
            Blob pdfBlob= pdfPage.getContent();
            base64Pdf = EncodingUtil.base64Encode(pdfBlob);
        } 
        else{            
            Blob pdfBlob = Blob.valueOf('UNIT TEST');
            base64Pdf = EncodingUtil.base64Encode(pdfBlob);

        }
        return base64Pdf;
    }

    /*Carga pdfs desde Content Version ID*/
    @AuraEnabled
    public static String getPdfFileAsBase64StringFromPDF(String idContentVersion) {

        System.debug('IdcontentVersion: ' + IdcontentVersion);
        String base64Pdf ='';
        
		if(!Test.isRunningTest()) 
        {
            ContentVersion contenido  = [SELECT VersionData FROM ContentVersion WHERE id = :idContentVersion];

            Blob pdfBlob = contenido.VersionData;
            base64Pdf = EncodingUtil.base64Encode(pdfBlob);
        } 
        else{
            Blob pdfBlob = Blob.valueOf(idContentVersion);
            base64Pdf = EncodingUtil.base64Encode(pdfBlob);
        }
        
        return base64Pdf;
    }
    
    @AuraEnabled
    public static String guardarDocumento(String fileBase64, String fileName, String fileExtension,String recordID){

        System.debug('guardarDocumento - fileBase64: ' + fileBase64);
        Blob fileContent = EncodingUtil.base64Decode(fileBase64);
        ContentVersion cv = new ContentVersion();
        cv.Title  = fileName;
        cv.VersionData  = fileContent;
        Date currentDate = Date.today();

        cv.pathOnClient = '/'+fileName+ '_' + currentDate +'.'+fileExtension;
        insert cv;

        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;


        ContentDocumentLink conDocLink = new ContentDocumentLink();
        conDocLink.LinkedEntityId = recordID;
        conDocLink.ContentDocumentId = conDoc; 
        conDocLink.shareType = 'V';
        sendPushNotification(recordID);
        insert conDocLink;
        return cv.id;
    }
    
    @AuraEnabled
    public static void sendPushNotification(String recordID){
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
         // Query the contract to get the ContractNumber
        Contract contractRecord = [SELECT ContractNumber FROM Contract WHERE Id = :recordID LIMIT 1];
        String contractNumber = contractRecord.ContractNumber;

        String titulo = 'Proceso de vincular archivos completado';
        String mensaje = 'Archivo vinculado para el siguiente contrato: ' + contractNumber;
        // Set the contents for the notification
        notification.setTitle(titulo);
        notification.setBody(mensaje);
        // Set the notification type and target

        String tipoNotificacionId = '';
        List<CustomNotificationType> listNotificationType = [SELECT Id, DeveloperName 
                                                                FROM CustomNotificationType 
                                                                WHERE DeveloperName='Notificacion_push'];
        if(!listNotificationType.isEmpty())
        {
            tipoNotificacionId = listNotificationType[0].Id;
        }

        notification.setNotificationTypeId(tipoNotificacionId);
        notification.setTargetId(recordID);
        Set<String> setRecipientId = new Set<String>();
        setRecipientId.add(UserInfo.getUserId());
    
        notification.send(setRecipientId);

    }
}