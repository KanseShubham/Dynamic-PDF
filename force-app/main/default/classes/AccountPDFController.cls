public class AccountPDFController {

    public List<PDFField> fieldData {get;set;}

    public AccountPDFController() {

        String recordId = ApexPages.currentPage().getParameters().get('recordId');
        String fields = ApexPages.currentPage().getParameters().get('fields');
        List<String> fieldList = fields.split(',');

        Account acc = [
            SELECT Name, AccountNumber, Site, Account_Summary__c,
                   Active__c, AnnualRevenue, CustomerPriority__c,
                   Industry, Rating, Website
            FROM Account
            WHERE Id = :recordId
        ];

        fieldData = new List<PDFField>();

        for(String f : fieldList){
            fieldData.add(new PDFField(
                getLabel(f),
                String.valueOf(acc.get(f))
            ));
        }
    }

    public static String getLabel(String api){
        Map<String,String> labels = new Map<String,String>{
            'Name' => 'Account Name',
            'AccountNumber' => 'Account Number',
            'Site' => 'Site',
            'Account_Summary__c' => 'Account Summary',
            'Active__c' => 'Active',
            'AnnualRevenue' => 'Annual Revenue',
            'CustomerPriority__c' => 'Customer Priority',
            'Industry' => 'Industry',
            'Rating' => 'Rating',
            'Website' => 'Website'
        };
        return labels.get(api);
    }

    public class PDFField{
        public String label {get;set;}
        public String value {get;set;}
        public PDFField(String l, String v){
            label = l;
            value = v;
        }
    }
}
