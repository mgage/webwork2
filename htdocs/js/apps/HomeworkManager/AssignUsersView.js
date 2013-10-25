/**
 *  This is the AssignUsersView which controls what users are assigned what problems.  The idea is to replace much of the 
 *  functionality in the Instructor Tools of the WebWork of yore. 
 * 
 **/


define(['Backbone', 
    'underscore','models/ProblemSet','views/EditableCell','config'], 
    function(Backbone, _,ProblemSet,EditableCell,config) {

    var AssignUsersView = Backbone.View.extend({
    	template: _.template($("#user-template").html()),
        headerInfo: {template: "#assignSets-header"},
    	initialize: function () {
    		_.bindAll(this,"render","initializeModel");
            this.users = this.options.users;
            this.problemSets = this.options.problemSets;
    	},
    	render: function ()
    	{
    		var self = this;
            this.initializeModel();
    		this.$el.html(_.template($("#assign-users-template").html()));
    		var userList = this.$(".assign-users-list");
    		this.users.each(function(user){
    			userList.append(self.template({user: user.get("user_id"), cid: user.cid, firstname: user.get("first_name"), 
                                            lastname: user.get("last_name")}));
    		});

    		var hwList = this.$("#assign-sets-list");
    		this.problemSets.each(function(set){
    			hwList.append("<li><input class='classlist-li' type='checkbox' data-setname='" + set.get("set_id") + "' id=set-'" + set.get("set_id") +"'>" 
    				+ "<label class='checklist' for=set-'" + set.get("set_id") + "'>" + set.get("set_id") + "</label>");
    		})

    		userList.height(0.6*$(window).height());
    		hwList.height(0.6*$(window).height());

    		// this.$("#due-date-row").html( (new EditableCell({model : this.model, type: "datetime", property: "open_date"})).render().el);
      //       this.$("#due-date-row").append( (new EditableCell({model : this.model, type: "datetime", property: "due_date"})).render().el);
      //       this.$("#due-date-row").append( (new EditableCell({model : this.model, type: "datetime", property: "answer_date"})).render().el);

            this.updateDates();
			return this;


    	},
    	events: {"click input.select-all": "toggleSelectAll",
    			 "click button#assign-users-sets": "assign"},
    	toggleSelectAll: function (evt){
    		var type = $(evt.target).attr("id").split("-")[1];
    		this.$("#assign-" + type + "-list input").prop("checked",this.$(evt.target).prop("checked"));
    	},
    	assign: function ()
    	{	
    		var allUserNames = this.users.pluck("user_id");
			var userNames = [];
			$("#assign-users-list input").each(function(i,v) { 
				if ($(v).prop("checked")) {userNames.push($(v).data("username"));}
			});
			var _users = this.users.filter(function(_user) { return (_(userNames).indexOf(_user.get("user_id")) >-1);});

			var setNames = [];
			$("#assign-sets-list input").each(function(i,v) { 
				if ($(v).prop("checked")) {setNames.push($(v).data("setname"));}
			});
			var _sets = this.problemSets.filter(function(_set) { return (_(setNames).indexOf(_set.get("set_id")) >-1);});

            console.log(_users);
            console.log(_sets);

            _(_sets).each(function(set) {set.assignToUsers(userNames)});
		},
		updateDates: function (){
			/*this.$("#assign-users-due-date-row").html( (new EditableCell({model : this.model, type: "datetime", 
							property: "open_date"})).render().el);
            this.$("#assign-users-due-date-row").append( (new EditableCell({model : this.model, type: "datetime", 
            				property: "due_date"})).render().el);
            this.$("#assign-users-due-date-row").append( (new EditableCell({model : this.model, type: "datetime", 
            				property: "answer_date"})).render().el);
*/
		},
		initializeModel: function(){
			 // set up the standard open and due dates first. 
            var timeAssignDue = config.settings.getSettingValue("pg{timeAssignDue}");
            var timezone = config.settings.find(function(v) { return v.get("var")==="timezone"}).get("value");


            var today = moment();
            var openDate = moment().add(7,"days");
            var assignOpenPriorToDue = config.settings.getSettingValue("pg{assignOpenPriorToDue}");
            var dueDate = moment().add(assignOpenPriorToDue,"minutes");
            var answerAfterDueDate = config.settings.getSettingValue("pg{answersOpenAfterDueDate}");
            var answerDate = moment().add(answerAfterDueDate,"minutes");
 

            // _openDate.toString("MM/dd/yyyy") + " at " + _openDate.toString("hh:mmtt")+ " " + tz[1];            

            this.model = new ProblemSet({set_id: "a_temporary_set_name",
                answer_date: answerDate.unix(),
                open_date: openDate.unix(),
                due_date: dueDate.unix()
            });
		}

    });

	var AssignSelectedUsersView = Backbone.View.extend({
		tagName: "div",
		template: _.template($("#modal-template").html()),
		initialize: function (){
			_.bindAll(this,"render");
			this.setUsers(this.options.users);
			this.setSets(this.options.sets);

			
			
		},
		render: function () {
			this.$el.html(this.template({header: "<h3>Assign to Selected Users</h3>", saveButton: "Assign",
											id: "assign-users-modal"}));
			this.$el.width(0.95*$(window).width());
			this.$("#assign-users-modal").modal();

			this.$("#assign-users-modal .modal-body").html($("#assign-user-set-template").html());

	
		},
		setUsers: function(_users) { this.users = _users;},
		setSets: function(_sets) {

			this.sets = _sets;
			var lastSet = _(this.sets).last();
			var openDate = lastSet.get("open_date");
			var dueDate = lastSet.get("due_date");
			var answerDate = lastSet.get("answer_date");
			// make a dummy ProblemSet that will be used to assign all sets the same info
			
			console.log("in setSets");
			this.model = new ProblemSet({set_id: "a_temporary_set_name", open_date: openDate, 
				due_date: dueDate, answer_date: answerDate}); 
			
		}
	});

    return AssignUsersView;


});