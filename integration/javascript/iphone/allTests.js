/**
* This is a script that tests the functionality of 
* ARIS using Bwoken, Tuneup_js and Xcode Instruments Automation.
*
**/

#import "../tuneup_js/tuneup.js"

var target = UIATarget.localTarget();
var app = target.frontMostApp();
var window = app.mainWindow();
target.logElementTree();

var username = "aris-test";
var password = "aris";
var gameName = "ARIS-Tester";

							/*  ******* RESER USER ******* */
var resetToLoginScreen = function()
{

	test("Reset to In-Game Menu.", function(target,app){
	
   // IF - Inside Character, Web Item, Normal Item
   if (app.navigationBar().buttons()["Back Button"].checkIsValid())
   		 {app.navigationBar().buttons()["Back Button"].tap(); } 
   //IF - Inside Plaque
   else if (window.staticTexts()["Continue"].checkIsValid())
    	 {
    	 window.staticTexts()["Continue"].tap();
	 	 app.navigationBar().buttons()["Back Button"].tap();
    	 }
   // IF - quick nav tapped or item tapped
   else if (app.actionSheet().cancelButton().checkIsValid())
   		  {app.actionSheet().cancelButton().tap(); }
  });
		

	test("Reset To Login Screen", function(target,app){
		 	// LEAVE GAME
		 	UIALogger.logMessage("If In-Game Menu present tap!");
		 	if (app.navigationBar().buttons()["In-Game Menu"].checkIsValid())
		 	{
		 	UIALogger.logMessage("Inside In-Game Menu IF");
				app.navigationBar().buttons()["In-Game Menu"].tap();
				window.staticTexts()["Leave Game"].tap();
				app.navigationBar().buttons()["Back Button"].tap();
			}
		 			
			
		 	// TAP ID CARD AND LOGOUT
		 	UIALogger.logMessage('If Settings Button present tap it!');
			if (app.navigationBar().buttons()["Settings Button"].checkIsValid())
			{
				UIALogger.logMessage("Inside Settings Button IF statement");
				app.navigationBar().buttons()["Settings Button"].tap();
				window.staticTexts()["Logout"].tap();
			}
	});	
};
						    /*  ******* SIMULATE LOGIN ******* */
var loginTest = function(username,password){
	

	
	//This is a tuneup_js test
	test("Login Screen", function(target, app){
		 		 		
		
		/*  ** Text Assertions ** */
		//Check "Create Account" Message
		UIALogger.logMessage("Check 'Create Account' Message");
		assertEquals("Create Account", window.buttons()["Create Account"].name());
		 
		//Check "Forgot Password" Button
		UIALogger.logMessage("Check 'Forgot Password?' Message");
		assertEquals("Forgot Password?",window.buttons()["Forgot Password?"].name());
		
		/*  ** Login to ARIS ** */ 
		//TYPE USERNAME
		 window.textFields()["Username Field"].tap();
		 app.keyboard().typeString(username);
		 
		// TYPE PASSWORD
		 window.secureTextFields()["Password Field"].tap();
		 app.keyboard().typeString(password);
	
		// CLICK LOGIN
		 target.delay(3);
		window.buttons()["Login"].tap();	
		 
	});
	
};

						    /*  ******* SIMULATE LOGIN ******* */
var searchGame = function(gameName){
	
	test("Search Game Test", function(target,app){
		
		/*  ** TAP SEARCH BAR ITEM ** */ 
		//Tap "Search"
		app.tabBar().buttons()["Search"].tap();	
	
		/*  ** TEST ASSERTIONS ** */ 
		UIALogger.logMessage("Check that the list is empty before starting");
		assertEquals("No results found", window.tableViews()["Empty list"].cells()["No results found"].name());	 
	
		/*  ** INPUT GAME NAME AND SEARCH ** */ 
		//Tap Search Bar and Input Name
		window.tableViews()["Empty list"].cells()["Cancel"].searchBars()[0].tap();
		app.keyboard().typeString(gameName);
		 
		// Tap Search
		app.keyboard().buttons()["Search"].tap();
	});
};

							/*  ******* SELECT GAME ******* */
var selectGame = function(gameName){
	
	test("Selecting Game", function(target,app) 
	{	
		//Tap the top Game
		target.frontMostApp().mainWindow().tableViews()["Empty list"].cells()[1].tap();
		 
		//RESET GAME IF "RESET" BUTTON IS THERE
		if(window.tableViews()["Empty list"].cells()["Reset"].checkIsValid())
		{ window.tableViews()["Empty list"].cells()["Reset"].tap();}
		 
		// TAP NEW GAME IF PRESENT 
		target.delay(3);
		window.tableViews()["Empty list"].cells()["New Game"].tap();
		 
	});

};

							/*  ******* ALERT FUNCTION ******* */
UIATarget.onAlert = function onAlert(alert) {

	/*  ** Log Alert ** */
  	var title = alert.name();	
  	UIALogger.logWarning("Alert with title '" + title + "' encountered.");
  
  	/*  ** ALERT: ARE YOU SURE? ** */
   	if (title == "Are you sure?")
   	{  	alert.buttons()["Reset"].tap();
   		return true;  //alert handled, so bypass the default handler
 	}
 	
 	/*  ** ALERT: ARIS USE CURRENT LOCATION ** */
	if (title == "“ARIS” Would Like to Use Your Current Location'")
	{	alert.buttons()["Ok"].tap();
		return true;
	}
	
	if (title == 'Scan Successful, But...'){
		UIALogger.logMessage('Requirements to see this item have not been met.');
		alert.buttons()["Ok"].tap();
		return true;
		}
	
	
	return false;
}
							/*  ******* INITIAL PLAQUE ******* */
var initialPlaque = function(){
	test("Dismiss Initial Plaque the Go To Map", function(target,app){
	
		/*  ** SCREEN ASSERTIONS ** */
		 target.delay(2);
		 UIALogger.logMessage('Assert Screenshot: Initial Plaque Object');
		 assertScreenMatchesImageNamed("initialPlaque", "Initial plaque did not match.");
	
		/*  ** UI INTERACTION ** */ 
		//Exit initial Plaque Item
		target.frontMostApp().mainWindow().staticTexts()["Continue"].tap();		 
		 
		//Exit initial plaque to map
		app.navigationBar().buttons()["In-Game Menu"].tap();
		window.tableViews()[0].cells()["Map"].tap();
		 
	});	
};

var quickTravelTest = function(){

test ('QuickTravel Off',function(target,app){

window.elements()["Item Quick Travel Off"].tap();
assertFalse(app.actionSheet().buttons()["Quick Travel"].checkIsValid(),"Quick Travel OFF but button is present");
app.actionSheet().cancelButton().tap();

});

test ('QuickTravel ON',function(target,app){

window.elements()["Conversation Tester"].tap();
assertTrue(app.actionSheet().buttons()["Quick Travel"].checkIsValid(),'Quick Travel On but button no present');
app.actionSheet().cancelButton().tap();

});


}

							/*  ******* NORMAL ITEM TESTS ******* */
var normalItem = function(){
	test ("Normal Item", function(target,app){
	
		/*  ** QUICK TRAVEL TO NORMAL ITEM ** */
		//TAP ON NORMAL ITEM AND QUICK TRAVEL  
		window.elements()["Normal Item"].tap();
		app.actionSheet().buttons()["Quick Travel"].tap();
		
		/*  ** SCREEN ASSERTIONS ** */
		target.delay(2);
		UIALogger.logMessage('Assert Screenshot: Normal Object'); 
		assertScreenMatchesImageNamed("normalItem", "Normal Item screen did not match");
  
		  
		/*  ** TEXT ASSERTIONS ** */
		//Check "Navigation bar says 'Normal Item'?"
		UIALogger.logMessage("Navigation bar says 'Normal Item' ?");
		assertEquals("Normal Item", app.navigationBar().name());
		    
		//Tap Three lines
		window.staticTexts()["..."].tap();	  
		  
		//Check "Item content says 'Normal Item' "
		UIALogger.logMessage("Item content says 'Normal Item' ?");
		assertEquals("Normal Item", window.scrollViews()[1].scrollViews()[0].webViews()[0].staticTexts()["Normal Item"].name());
		  
		/*  ** EXIT NORMAL ITEM ** */  		  
		app.navigationBar().buttons()["Back Button"].tap();
		  
		
		  
		
	});
};

							/*  ******* PLAQUE OBJECT TEST ******* */
var plaque = function(){
	test("Plaque", function(target,app){
		
		/*  ** ENTER PLAQUE ITEM ** */ 
		//TAP ON PLAQUE ON MAP 
		window.elements()["Plaque"].tap();
		app.actionSheet().buttons()["Quick Travel"].tap();
		
		/*  ** SCREEN ASSERTIONS ** */  
		target.delay(2); 
		UIALogger.logMessage('Assert Screenshot: Plaque Object');
  		assertScreenMatchesImageNamed("plaque", "Plaque screen did not match");
		
		/*  ** TEXT ASSERTIONS ** */
		UIALogger.logMessage("Navigation bar says 'Plaque' ?");
		assertEquals("Plaque",target.frontMostApp().navigationBar().name());
		 
		UIALogger.logMessage("Plaque content says 'Plaque Content' ");
		assertEquals("Plaque Content", window.scrollViews()[0].scrollViews()[0].webViews()[0].staticTexts()["Plaque Content"].name());
		 
 		/*  ** EXIT PLAQUE ** */  
		window.staticTexts()["Continue"].tap();
	
	});	
};

							/*  ******* GREETING CHARACTER TESTS ******* */
var greetingCharacter = function(){
	test("Enter Greeting Character", function(target,app){
		 
		/*  ** ENTER GREETING CHARACTER ** */ 
		window.elements()["Greeting/Closing Character"].tap();
		app.actionSheet().buttons()["Quick Travel"].tap();
		 
		/*  ** TEXT ASSERTIONS ** */
		UIALogger.logMessage("Navigation says 'You'? ");	
		assertEquals("You", app.navigationBar().name());
		 
		 });	
	
	test("PC Character Test",function(target,app){		
		 /*  ** TEXT ASSERTIONS ** */
		assertEquals("I'm the PC",window.scrollViews()[3].scrollViews()[0].webViews()[0].staticTexts()["I'm the PC"].name())
		 
		 /*  ** Continue ** */
		 target.delay(1);
		 window.staticTexts()["Continue"].tap();
		 
		 });
	
	test("NPC Character Test",function(target,app){
		 
		 /*  ** TEXT ASSERTIONS ** */
		assertEquals("I'm the NPC",window.scrollViews()[1].scrollViews()[0].webViews()[0].staticTexts()["I'm the NPC"].name())
		
		
		/*  ** Continue ** */
		target.delay(1);
		window.staticTexts()["Continue"].tap();
		
		 });
	
	test("NOC With Custom Media Test",function(target,app){

		 /*  ** TEXT ASSERTIONS ** */
		 assertEquals("NOC with custom media",window.scrollViews()[1].scrollViews()[0].webViews()[0].staticTexts()["NOC with custom media"].name())
		 
		 /*  ** Continue ** */
		 target.delay(1);
		 window.staticTexts()["Continue"].tap();
		 });
	
	test("Leaving Converstaion Tester", function(target,app){
		/*  ** EXIT CONVERSATION TESTER ** */
		//Leave Conversation
		target.delay(2);
		window.scrollViews()[0].scrollViews()[0].webViews()[0].staticTexts()["Leave Conversation"].tap();
		 });

		 
};

							/*  ******* ENTER CONVERSATION TESTER ******* */
var enterConversationTester = function(){
	test("Enter Conversation Tester", function(target, app) {
		window.elements()["Conversation Tester"].tap();
		app.actionSheet().buttons()["Quick Travel"].tap();
		window.staticTexts()["Continue"].tap();
	 });	
};

							/*  ******* NORMAL SCRIPTS TESTS ******* */
var normalScriptTests = function(){
	
		test("No Script", function(target,app){
		 
		//No Script
		window.scrollViews()[0].scrollViews()[0].webViews()[0].tap();
		window.staticTexts()["Continue"].tap();
	
		});
		
		test("NPC and PC Tag", function(target,app){
		target.delay(2);
		window.scrollViews()[0].scrollViews()[0].webViews()[0].tap();
			 
		target.delay(1);
		window.staticTexts()["Continue"].tap();
		target.delay(1);
		window.staticTexts()["Continue"].tap();
		
		});
		
		test("Item Tag", function(target,app){
		target.delay(1);
		window.scrollViews()[0].scrollViews()[0].webViews()[0].tap();
		target.delay(1);
		app.navigationBar().buttons()["Back Button"].tap();
			 
		});
	
	test("Plaque Tag",function(target,app){
		 
		window.scrollViews()[0].scrollViews()[0].webViews()[0].tap();
		target.delay(1);
		window.staticTexts()["Continue"].tap();
		 
		 
		 });
	
		// Video Tag == This is funky, it exited me.
	
		// Panoramic Tag  == This is funky , it exited me.
		
		// End Normal Script Tests	
};

							/*  ******* EXIT TO SCRIPTS TESTS ******* */
var exitToScripts = function() {
	
	test("Exit To Webpage", function(target,app){
		//Click Exit to Webpage
		target.frontMostApp().mainWindow().scrollViews()[0].scrollViews()[2].webViews()[0].tap();
		
		/*  ** SCREEN ASSERTIONS ** */
		target.delay(2);
		UIALogger.logMessage('Assert Screenshot: Aris Website Loaded');
		target.delay(2);
		assertScreenMatchesImageNamed("arisWebsite", "Images did not match");
		
		target.delay(2);
		app.navigationBar().buttons()["Back Button"].tap();
	});
	
	test("Exit To Map", function(target,app){
		target.frontMostApp().mainWindow().scrollViews()[0].scrollViews()[2].webViews()[0].tap();
		target.frontMostApp().mainWindow().staticTexts()["Continue"].tap();
	});
	test("Back To Character", function(target,app){
		window.elements()["Conversation Tester"].tap();
		app.actionSheet().buttons()["Quick Travel"].tap();
		window.staticTexts()["Continue"].tap();
	});
	test("Exit To Plaque", function(target,app){
		window.scrollViews()[0].scrollViews()[2].webViews()[0].tap();
		window.staticTexts()["Continue"].tap();
		window.staticTexts()["Continue"].tap();
	});
	test("Back To Character", function(target,app){
		window.elements()["Conversation Tester"].tap();
		target.delay(1);
		app.actionSheet().buttons()["Quick Travel"].tap();
		target.delay(1);
		window.staticTexts()["Continue"].tap();
	});
	test("Exit To Item", function(target,app){
		target.delay(1);
		window.scrollViews()[0].scrollViews()[2].webViews()[0].tap();
		target.delay(1);
		window.staticTexts()["Continue"].tap();
		target.delay(1);
		app.navigationBar().buttons()["Back Button"].tap();
		 });
	test("Back To Character", function(target,app){
		target.delay(2);
		window.elements()["Conversation Tester"].tap();
		target.delay(1);
		app.actionSheet().buttons()["Quick Travel"].tap();
		target.delay(1);
		window.staticTexts()["Continue"].tap();
	});
	test("Exit To Character", function(target,app){
		window.scrollViews()[0].scrollViews()[2].webViews()[0].tap();
		target.delay(1);
		window.staticTexts()["Continue"].tap();
		target.delay(1);
		window.staticTexts()["Continue"].tap();
		target.delay(1);
		window.scrollViews()[0].scrollViews()[0].webViews()[0].tap();
	});
	test("Back To Character", function(target,app){
		target.delay(1);
		window.elements()["Conversation Tester"].tap();
		target.delay(1);
		app.actionSheet().buttons()["Quick Travel"].tap();
		target.delay(1);
		window.staticTexts()["Continue"].tap();
	});
	test("Exit To Webpage", function(target,app){
		window.scrollViews()[0].scrollViews()[2].webViews()[0].tap();
		window.staticTexts()["Continue"].tap();
		app.navigationBar().buttons()["Back Button"].tap();
	});
		// EXIT TO PANORAMIC -- this is broken

};

							/*  ******* SCANNER TESTS ******* */
var testDecoder = function() {


test("Scanner: Access Normal Item", function(target, app){
	 
	 //Go Into Decoder From MAP	
	 app.navigationBar().buttons()["In-Game Menu"].tap();
	 window.tableViews()["Empty list"].cells()["Scanner"].tap();
	 
	 // Plaque Decoder
	 window.textFields()[0].tap();
	 target.delay(1);
	 app.keyboard().typeString('8994\n');
	 
	 /*  ** SCREEN ASSERTIONS ** */
		target.delay(2);
		UIALogger.logMessage('Assert Screenshot: Normal Object'); 
		assertScreenMatchesImageNamed("normalItem", "Normal Item screen did not match");
		
	 //Entered plaque?
	 target.frontMostApp().mainWindow().staticTexts()["Continue"].tap();
	
	 // Clear text Field
	 window.textFields()[0].tap();
	 target.delay(1);
	 target.frontMostApp().keyboard().keys()["Delete"].tap();
	 target.delay(1);
	 target.frontMostApp().keyboard().keys()["Delete"].tap();
	 target.delay(1);
	 target.frontMostApp().keyboard().keys()["Delete"].tap();
	 target.delay(1);
	 target.frontMostApp().keyboard().keys()["Delete"].tap();
	 
	 });
	 
test("Scanner: Requirements Not Met", function(target,app){
		 
		 
	 //Go Into Decoder From MAP	
	 app.navigationBar().buttons()["In-Game Menu"].tap();
	 window.tableViews()["Empty list"].cells()["Scanner"].tap();
	 
	// Normal Item Decoder
	 window.textFields()[0].tap();
	 target.delay(1);
	 app.keyboard().typeString('1472\n');
	 

	 // Clear text Field
	 target.delay(1);
	 window.textFields()[0].tap();
		 target.delay(1);
	 target.frontMostApp().keyboard().keys()["Delete"].tap();
		 target.delay(1);
	 target.frontMostApp().keyboard().keys()["Delete"].tap();
		 target.delay(1);
	 target.frontMostApp().keyboard().keys()["Delete"].tap();
		 target.delay(1);
	 target.frontMostApp().keyboard().keys()["Delete"].tap();
		 
		 
		 });

};


							/*  ******* Create Image Asserter ******* */
var imageAsserter = function(){
		 
	createImageAsserter('integration/javascript/tuneup_js', 'integration/tmp/results', 'integration/ref_images');
				 
UIALogger.logMessage("Image Asserter Finished");
};

	
/* Take Screenshots with code below
		//target.delay(2);
		//UIATarget.localTarget().captureAppScreenWithName('normalItem'); 
*/

/////////////////// Test AREA

var locationMigration = function() {
 // speed is in meters/sec  
 var points = [  
                 {location:{latitude:40.828300000,longitude:-96.69941700}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.830158000,longitude:-96.700531000}, options:{speed:11, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.83086000,longitude:-96.700829000}, options:{speed:12, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.830860000,longitude:-96.700829000}, options:{speed:13, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.830551000,longitude:-96.70187400}, options:{speed:15, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.8304710004,longitude:-96.70233900}, options:{speed:15, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.830471000,longitude:-96.702339000}, options:{speed:9, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.830349000,longitude:-96.702332000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.830471000,longitude:-96.701782000}, options:{speed:3, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.830719000,longitude:-96.700958000}, options:{speed:6, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.8307190001,longitude:-96.700958000}, options:{speed:10, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.83005900,longitude:-96.700661000}, options:{speed:15, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.827221000,longitude:-96.699043000}, options:{speed:15, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}}, 
                 {location:{latitude:40.825829000,longitude:-96.698181000}, options:{speed:12, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.82502000,longitude:-96.697578000}, options:{speed:10, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.822899000,longitude:-96.695374000}, options:{speed:5, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.821571000,longitude:-96.693329000}, options:{speed:5, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.821331000,longitude:-96.693047000}, options:{speed:6, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.820938000,longitude:-96.692703000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.820351000,longitude:-96.692413000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.819988000,longitude:-96.692307000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.819489000,longitude:-96.69229900}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.818859000,longitude:-96.692322000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.818501000,longitude:-96.692421000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.818008000,longitude:-96.692741000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.817131000,longitude:-96.693703000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.816898000,longitude:-96.693871000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.816490000,longitude:-96.694054000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.815819000,longitude:-96.694099000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.813580000,longitude:-96.694092000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.813580000,longitude:-96.694092000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.813560000,longitude:-96.685478000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.813499000,longitude:-96.685188000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.813450000,longitude:-96.682411000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},   
                 {location:{latitude:40.813450000,longitude:-96.682411000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.804840000,longitude:-96.682419000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.799541000,longitude:-96.682487000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.797611000,longitude:-96.682487000}, options:{speed:15, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},   
                 {location:{latitude:40.797508000,longitude:-96.682426000}, options:{speed:15, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.793510000,longitude:-96.682449000}, options:{speed:15, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.793190000,longitude:-96.682457000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.793121000,longitude:-96.682518000}, options:{speed:15, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude: 40.791660000,longitude:-96.682518000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude: 40.791580000,longitude:-96.682472000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude: 40.790779000,longitude:-96.682457000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.784431000,longitude:-96.682510000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.784431000,longitude:-96.682510000}, options:{speed:15, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.784451000,longitude:-96.687378000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.784451000,longitude:-96.687378000}, options:{speed:15, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.780891000,longitude:-96.687401000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.780891000,longitude:-96.687401000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}},  
                 {location:{latitude:40.780880000,longitude:-96.687210000}, options:{speed:8, altitude:200, horizontalAccuracy:10, verticalAccuracy:15}} 
                           ];  

//set the app to watch for the country club

var approachingLabelText;
var approachingLogicWorked;

//now drive
for (var i = 0; i < points.length; i++){  
        target.setLocationWithOptions(points[i].location,points[i].options);  
     
        approachingLabelText = window.staticTexts()[1].value();
        
        if(approachingLabelText == "You're approaching the Country Club!"){
                approachingLogicWorked = true;
                 UIALogger.logDebug("Approaching country club label was displayed");
        }else
                UIALogger.logDebug("Approaching country club label was not displayed");         
}




}


							/*  ******* MAIN ******* */
							
							/////////////// Reset Game and Create Image Asserter 
// Reset the game from anywhere in the application
resetToLoginScreen();

//Test Login Image 
imageAsserter();
								//////////////// Begin Tests
//Login to account
loginTest(username, password);

//Search for Game
searchGame(gameName);

// Select Game
selectGame();
								/////////////// Begin In Game Test 
					
// Dismiss Initial Plaque
initialPlaque();

//Test Locations
//locationMigration();

//QuickTravel Test
quickTravelTest();

//Normal Item Test
normalItem();

//Plaque Test 
plaque();
 
// Greeting Character Dialogue Test
greetingCharacter();

// Has the Conversation Tester Dropped?
enterConversationTester();

// Test Normal Scripts
normalScriptTests();
 
//Test Exit to Scripts
exitToScripts();


//Test Decoder
testDecoder();

							//////////////// End In Game Test and Reset 
							
// Reset Back to Login Screen
resetToLoginScreen();



