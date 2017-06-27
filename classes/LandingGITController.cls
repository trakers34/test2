/**
 * Created by guillaume.rebmann on 6/21/17.
 */

public with sharing class LandingGITController {
    public static String CRON_NAME = 'Digital Deer GIT - ';
    public String mode {get;set;}
    public String selectedItem {get;set;}


    public GitSchedule GitScheduleItem {get;set;}
    public static Set<String> availableTypes = new Set<String>{'Github'};
    public static Set<String> availableFrequencies = new Set<String>{'Every Hour','Every 5 Hours','Every 10 Hours','Every days','Every week','Every Month'};


    public LandingGITController(){
        this.mode = 'view';
    }

    public void cancel(){
        this.mode = 'view';
        this.GitScheduleItem = null;
    }

    public void save(){
        bounceback__GitSettings__c gitSetting = this.GitScheduleItem.getGitSetting();
        if(this.mode == 'new' && [select count() from bounceback__GitSettings__c where name =:gitSetting.Name] == 1){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'This name is already used'));
        }else{
            upsert gitSetting Name;
            this.mode = 'view';
        }
        String name = CRON_NAME+gitSetting.Name;
        for(CronTrigger cJob : [select id from CronTrigger where CronJobDetail.Name = :name]){
            System.abortJob(cJob.Id);
        }

        scheduleGIT.process(gitSetting.Name);

    }

    public void createSchedule(){
        this.mode = 'new';
        this.GitScheduleItem = new GitSchedule();
    }

    public void editSchedule(){
        this.mode = 'edit';
        this.GitScheduleItem = new GitSchedule(bounceback__GitSettings__c.getValues(selectedItem));
    }

    public void deleteSchedule(){

        bounceback__GitSettings__c item = bounceback__GitSettings__c.getValues(selectedItem);
        String name = CRON_NAME+item.Name;
        for(CronTrigger cJob : [select id from CronTrigger where CronJobDetail.Name = :name]){
            System.abortJob(cJob.Id);
        }
        delete item;
    }


    public List<GitSchedule> getSchedules(){
        List<GitSchedule> returned = new List<GitSchedule>();

        Map<String,bounceback__GitSettings__c> settings = bounceback__GitSettings__c.getAll();
        for (String key : settings.keySet()) {
            returned.add(new GitSchedule(settings.get(key)));
        }

        return returned;
    }

    public List<SelectOption> getTypes(){
        List<SelectOption> returned = new List<SelectOption>();

        for(String key : availableTypes){
            returned.add(new SelectOption(key,key));
        }
        return returned;

    }

    public List<SelectOption> getFrequencies(){
        List<SelectOption> returned = new List<SelectOption>();

        for(String key : availableFrequencies){
            returned.add(new SelectOption(key,key));
        }
        return returned;
    }








    public class GitSchedule{
        public String name {get;set;}
        public String type {get;set;}
        public String frequency {get;set;}
        public Boolean active {get;set;}
        public Id id {get;set;}

        public Boolean IncludeApexClasses{get;set;}
        public Boolean IncludeTriggers{get;set;}
        public Boolean IncludeVisualForcePages{get;set;}

        public GitSchedule(){}

        public GitSchedule(bounceback__GitSettings__c item){
            this.name = item.name;
            this.id = item.id;
            this.type = item.bounceback__Type__c;
            this.frequency = item.bounceback__Frequency__c;
            this.active = item.bounceback__Active__c;
            this.IncludeApexClasses = item.bounceback__IncludeApexClasses__c;
            this.IncludeTriggers = item.bounceback__IncludeTriggers__c;
            this.IncludeVisualForcePages = item.bounceback__IncludeVisualForcePages__c;
        }

        public bounceback__GitSettings__c getGitSetting(){
            bounceback__GitSettings__c  item = new bounceback__GitSettings__c();
                    item.name                                       = name;
                    item.bounceback__Type__c                        = type;
                    item.bounceback__Frequency__c                   = frequency;
                    item.bounceback__Active__c                      = active;
                    item.bounceback__IncludeApexClasses__c          = IncludeApexClasses;
                    item.bounceback__IncludeTriggers__c             = IncludeTriggers;
                    item.bounceback__IncludeVisualForcePages__c     = IncludeVisualForcePages;
            return item;
        }
    }

}