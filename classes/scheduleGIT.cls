/**
 * Created by guillaume.rebmann on 6/21/17.
 */

public with sharing class scheduleGIT implements Schedulable{

    public String target {get;set;}

    public scheduleGIT(String target){
        this.target = target;
    }

    public void execute(SchedulableContext SC) {
        process(this.target);
        System.abortJob(SC.getTriggerId());
    }

    public static void init(){
        Map<String,bounceback__GitSettings__c> settings = bounceback__GitSettings__c.getAll();
        for (String key : settings.keySet()) {
            process(key);
        }
    }

    @Future (callout=true)
    public static void process(String target){
        Map<String,Object> returned = new Map<String,Object>{
                'apex'=> new List<Id>(),
                'page'=> new List<Id>(),
                'trigger'=> new List<Id>()
        };

        bounceback__GitSettings__c settings = bounceback__GitSettings__c.getValues(target);


        returned.put('settings',new Map<String,Object>{
                'name'=> target,
                'apex'=> settings.bounceback__IncludeApexClasses__c,
                'trigger'=> settings.bounceback__IncludeTriggers__c,
                'page'=> settings.bounceback__IncludeVisualForcePages__c,
                'git' => new Map<String,String>{
                        'username'=> settings.bounceback__UsernameGIT__c,
                        'password'=> settings.bounceback__passwordGIT__c
                }
        });




        Datetime dateSelector = settings.bounceback__CurrentSelector__c; // Custom Setting

        if(settings.bounceback__IncludeApexClasses__c){
            for(ApexClass apexClassItem : [select id from ApexClass where lastModifiedDate >= :dateSelector and NamespacePrefix = null]){
                ((List<Id>)returned.get('apex')).add(apexClassItem.Id);
            }
        }

        if(settings.bounceback__IncludeVisualForcePages__c) {
            for (ApexPage apexPageItem : [select id from ApexPage where lastModifiedDate >= :dateSelector and NamespacePrefix = null]) {
                ((List<Id>) returned.get('page')).add(apexPageItem.Id);
            }
        }

        if(settings.bounceback__IncludeTriggers__c){
            for(ApexTrigger apexTriggerItem : [select id from ApexTrigger where lastModifiedDate >= :dateSelector and NamespacePrefix = null]){
                ((List<Id>)returned.get('trigger')).add(apexTriggerItem.Id);
            }
        }




        String chronExpression = '0 0 * * * ?';
        System.schedule( 'Digital Deer GIT - '+target, chronExpression,new scheduleGIT(target));
        System.debug(JSON.serialize(returned));

        if(((List<Id>)returned.get('trigger')).size() > 0 || ((List<Id>)returned.get('page')).size() > 0 || ((List<Id>)returned.get('apex')).size() > 0){
            // Here we send the information to server
        }

    }



}