public with sharing class AccountPDFGenerator {

    @AuraEnabled
    public static void generateFromLWC(String recordId, String selectedFields){
        System.enqueueJob(new PDFQueueable(recordId, selectedFields));
    }

    public class PDFQueueable implements Queueable, Database.AllowsCallouts {

        String recordId;
        String selectedFields;

        public PDFQueueable(String rId, String fields){
            recordId = rId;
            selectedFields = fields;
        }

        public void execute(QueueableContext qc){

            PageReference pg = Page.AccountDynamicPDF;
            pg.getParameters().put('recordId', recordId);
            pg.getParameters().put('fields', selectedFields);

            Blob pdf = pg.getContentAsPDF();

            ContentVersion cv = new ContentVersion();
            cv.Title = 'Account_Report';
            cv.PathOnClient = 'Account_Report.pdf';
            cv.VersionData = pdf;
            insert cv;

            Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = recordId;
            cdl.ContentDocumentId = docId;
            cdl.ShareType = 'V';
            insert cdl;
        }
    }
}
