public with sharing class AccountPDFGenerator {

    // =====================================================
    // Called from LWC to Generate PDF (Async)
    // =====================================================
    @AuraEnabled
    public static void generateFromLWC(String recordId, String selectedFields){
        System.enqueueJob(new PDFQueueable(recordId, selectedFields));
    }

    // =====================================================
    // Queueable Class to Generate and Attach PDF
    // =====================================================
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

            Id docId = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
            ].ContentDocumentId;

            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = recordId;
            cdl.ContentDocumentId = docId;
            cdl.ShareType = 'V';
            insert cdl;
        }
    }

    // =====================================================
    // 3️⃣ Called from LWC to Send Latest PDF to Customer
    // =====================================================
    @AuraEnabled
public static void sendLatestPDFToCustomer(Id recordId){

    // 1️⃣ Get Account name and email
    Account acc = [
        SELECT Name, Email__c
        FROM Account
        WHERE Id = :recordId
        LIMIT 1
    ];

    if(String.isBlank(acc.Email__c)){
        throw new AuraHandledException('Account does not have an email address.');
    }

    // 2️⃣ Get ContentDocumentId from link
    ContentDocumentLink link = [
        SELECT ContentDocumentId
        FROM ContentDocumentLink
        WHERE LinkedEntityId = :recordId
        LIMIT 1
    ];

    // 3️⃣ Get latest version of ONLY our PDF
    ContentVersion cv = [
        SELECT VersionData, Title
        FROM ContentVersion
        WHERE ContentDocumentId = :link.ContentDocumentId
        AND Title = 'Account_Report'
        ORDER BY VersionNumber DESC
        LIMIT 1
    ];

    // 4️⃣ Attachment
    Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
    attach.setFileName(cv.Title + '.pdf');
    attach.setBody(cv.VersionData);

    // 5️⃣ Email
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(new String[]{acc.Email__c});
    mail.setSubject('Your Account Details PDF');
    mail.setPlainTextBody(
        'Hello ' + acc.Name + ',\n\nPlease find attached your account details PDF.'
    );
    mail.setFileAttachments(new Messaging.EmailFileAttachment[]{attach});

    Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
}
}