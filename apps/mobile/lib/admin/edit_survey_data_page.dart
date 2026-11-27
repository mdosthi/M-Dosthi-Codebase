//Author: Soumyajit Das, Koustav Ghosh
//Date: 20/07/2024

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:mdosthi_app/backend/database_helper.dart';
import 'edit_survey_response.dart';

class SurveyData extends StatefulWidget {
  final String currsurveyData;
  final String rid;
  final String sid;
  final String record_type;
  
  const SurveyData(this.currsurveyData, this.rid, this.sid, this.record_type, {super.key});
  @override
  State<SurveyData> createState() => _SurveyDataState();
}

class _SurveyDataState extends State<SurveyData> {
  List<MapEntry<String, dynamic>> entries = [];
  final _formKey = GlobalKey<FormState>();
  Map<String, TextEditingController> controllers = {};
  List<Map<String, dynamic>> questions = [];
  Map<String, dynamic> responses = {};
  Map<String, bool?> checkboxValues = {};
  Map<String, dynamic> checkboxValues2 = {};
  Map<String, String>? dropDownIndex={};
List<Map<String, dynamic>> pastResponses = [];

  @override
  void initState() {
    super.initState();
    displayResponseData();
  }

  void displayResponseData() async{

    
    final details = await DatabaseHelper.instance.getFormWithSid(widget.sid);
    // dynamic jsonContentDetailSource = "";
    // dynamic jsonContentTemplateSource = "";
    
    dynamic jsonContent = "";

    if(widget.record_type=="0")
    {
        jsonContent = jsonDecode(details[0]['template_source'])['template_source'];
    }
    else
    {
        jsonContent = jsonDecode(details[0]['details_source'])['details_source'];
    }


    if (jsonContent != "") {
      List<Map<String, dynamic>> mapList =
          List<Map<String, dynamic>>.from(jsonContent);
      // print(mapList);

      setState(() {
        questions = mapList;
      });
    }
    // var x = jsonDecode(widget.currsurveyData);
    // setState(() {
    //       pastResponse = x;
    //     });

    print("Show form format");
    print(questions);

    //final fid_ = await DatabaseHelper.instance.getfidBysidandAttributeName(widget.sid, key);







    final data = json.decode(widget.currsurveyData);
    entries = data.entries.toList();
    
    
    // for (var entry in entries) {
    //   print("entriessssssssssss");
    //   print(entry);
    //   controllers[entry.key] =
    //       TextEditingController(text: entry.value.toString());
    // }

    for (var qn in questions){
      
      var key=qn['attrname'];
      var attrtype=qn['attrtype'];
      
      
      var value="";
      for (var entry in entries) {
        if(entry.key==key)
        {
            value=entry.value.toString();
            print(key+"  --  "+value);
        }
        
      }
      if(attrtype=="single")
      {
      //updateCheckboxMultiple(question,index,value);
        print(qn['attrvalues']);
        String options_=qn['attrvalues'];
        dynamic options;
        options = options_.split(';');
              
        var index=options.indexOf(value);
        
        handleOptionSelected(key,value);      
        dropDownIndex?[key]=value;
        
      }
      else
      {
        controllers[key] =TextEditingController(text: value.toString());
        handleOptionSelected(key, value.toString());
      }

    }


  }

  void saveResponses() async {
    String rid = widget.rid;
    //if (_formKey.currentState!.validate()) {
      Map<String, dynamic> updatedResponses = {};
      // for (var entry in entries) {
      //   updatedResponses[entry.key] = controllers[entry.key]!.text;
      // }

      for (var qn in questions){
      
      var key=qn['attrname'];
      var qtype=qn['attrtype'];
      if(qtype=="single")
      {
        updatedResponses[key] =  responses[key];
      }
      else{
        updatedResponses[key] = controllers[key]!.text;
      }
      final fid = await DatabaseHelper.instance.getfidBysidandAttributeName(widget.sid, key);
      print("key --- fid");
      print(key+"---"+fid);

      final success = await DatabaseHelper.instance.updateResponsesByField(updatedResponses[key], rid,fid);

      }
      print("updatedResponses :");
      print(updatedResponses);

      //final success =await DatabaseHelper.instance.updateResponses(updatedResponses, rid);
      String updatedStringResponse = json.encode(updatedResponses);
      final success = await DatabaseHelper.instance
          .updateResponses(updatedStringResponse, rid);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Responses saved successfully')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to save responses')));
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DisplaySurveyResponses(),
        ),
      );
    //}
  }

  void handleOptionSelected(String question, String selectedOption) {
    setState(() {
      responses[question] = selectedOption;
    });
  }
Widget _buildSmallTextField(

      String questionText, String hintText, String unit) {
    return SizedBox(
      width: 400, // Set the desired width
      height: 50,
      child: TextField(
        onChanged: (value) {
          handleOptionSelected(questionText, value);
        },
        decoration: InputDecoration(
          isDense: true,
          hintText: (unit.isNotEmpty) ? "$hintText in $unit" : hintText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

   void updateCheckboxMultiple(String question,int index,bool? value)
  {
    setState(() {
                      print('$question - $index - $value');
                      
                      checkboxValues2[question][index]["value"] = value;
                      print('Before update - $responses');

                      
                      print('checkboxValues2 - ');
                      print(checkboxValues2[question]);
                      print(responses[question]);
                      
                      if(responses[question]==null)
                      {
                        responses[question]=[];
                      }
                      if (responses[question].contains(checkboxValues2[question][index]["title"])) 
                      {
                        responses[question].remove(checkboxValues2[question][index]["title"]);
                      } 
                      else 
                      {
                        responses[question].add(checkboxValues2[question][index]["title"]);                        
                      }

                      print('After Update - $responses');
                    });
  }

  Widget _buildDropdownWidgetMultiple(List<dynamic> dropDownList,String question) {


      for (var i = 0; i < responses[question].length; i++) {

          var val=responses[question][i];
          print("val - $val");

          for (var j = 0; j < checkboxValues2[question].length; j++) {

            if(val==checkboxValues2[question][j]["title"]) {
              checkboxValues2[question][j]["value"]=true;
            }
        }
      } 

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 64.0),
        child: Column(
          children: [
            Column(
              children: List.generate(
                dropDownList.length,
                (index) => CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    dropDownList[index]["title"],
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.black,
                    ),
                  ),
                  value: checkboxValues2[question][index]["value"],
                  onChanged: (value) {
                    setState(() {
                      checkboxValues2[question][index]["value"] = value;
                    });
                    print('Selected checkbox - $index');
                    updateCheckboxMultiple(question,index,value);
                  },
                ),
              ),
            ),
            //const SizedBox(height: 64.0),
            
          ],
        ),
      
    );
    }

    Widget _buildDropdownWidget(List<String> dropDownList,String question) {

//String? dropDownIndex;
    //dropDownIndex?[question]='';
     //List<String> options_list=['One', 'Two', 'Free', 'Four'];
     //dropDownList=options_list;
  
      return DropdownButton(
        
     icon: const Icon(Icons.expand_circle_down),
     elevation: 16,
     dropdownColor: Colors.white,
     hint: const Text("select"),
     enableFeedback: true,
     iconSize: 16,
     borderRadius: BorderRadius.circular(16),
     style: const TextStyle(color: Color(0xFF0D6B44)),
     underline: Container(
      height: 2,
      color: const Color(0xFF138A4E),
     ),     
  items: dropDownList.map((value) => DropdownMenuItem(value: value,child: Text(value),)).toList(),
  onChanged: (String? index) {
      setState(() {
        //dropDownIndex[question] = index;
        if(index!=null)
        {
          dropDownIndex?[question] = index;
          handleOptionSelected(question, index);
        }
        //responses[question] = index;
        print('responses[question] : $index');
      });
  },
  value: dropDownIndex?[question],
      );
    }

Widget questionTextWithResponse(
      String questionText, String unit_, dynamic req) {
        print("questionText - $questionText");
        
    if (unit_.isNotEmpty && unit_ != "none") {
      questionText += " (in $unit_)";
    }
    // if (pastResponse[questionText] != null) {
    // }
    if (req == 1 || req == '1' || (req == 'true')) {
      questionText += '*';
    }
    return Text(
      questionText,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question) {
    final questionText = question['attrname'];
    final questionType = question['attrtype'];
    final options_ = question['attrvalues'];
    final unit_ = question['attrunit'];
    final req = question['attrreq'];
    print('$questionText - $questionType - $options_ - $unit_ - $req'); 
    //Relation - single - Self;Mother;Father;Mother-in-law;Father-in-law;Sister;Brother; - none - true
    dynamic options;
    if (options_ == null) {
      options = null;
    } else {
      options = options_.split(';');
    }

  List<String> listOfOptions=[];
  if (questionType == 'single' || questionType == 'multiple' ) {
      
      
      for (var i = 0; i < options.length-1; i++) {
          listOfOptions.add(options[i]);
        }
      print('list_of_options : $listOfOptions');

      List checkListItems = []; 

    if(questionType == 'multiple')    {
      for (var i = 0; i < options.length-1; i++) {
          checkListItems.add({"id":i,"value":false,"title":options[i]});
        }    
      checkboxValues2[questionText]=checkListItems;  


      return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              questionTextWithResponse(questionText, unit_, req),
              const SizedBox(height: 10),
              //_buildDropdownWidget(list_of_options,questionText),
              _buildDropdownWidgetMultiple(checkListItems,questionText)
            ],
          ),
        ),
      ),
    );
    }
    else{

      return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              questionTextWithResponse(questionText, unit_, req),
              const SizedBox(height: 10),
              _buildDropdownWidget(listOfOptions,questionText),
              //_buildDropdownWidgetMultiple(checkListItems,questionText)
            ],
          ),
        ),
      ),
    );
    }
      
      //https://stackoverflow.com/questions/49273157/how-to-implement-drop-down-list-in-flutter
      
      
      //List<String> options_list=['One', 'Two', 'Free', 'Four'];
      //return _buildDropdownWidget(list_of_options);
      //responses[questionText]=[];

       
      
  }




    if (questionType == 'Check Box') {
      // responses[questionText] = "false";
      return Row(
        children: [
          Checkbox(
            value: checkboxValues[questionText] ?? false,
            onChanged: (bool? newValue) {
              print('value is $newValue');
              print(checkboxValues[questionText]);
              setState(() {
                checkboxValues[questionText] = newValue ?? false;
                responses[questionText] =
                    (checkboxValues[questionText] == true) ? "true" : "false";
              });
              print(checkboxValues[questionText]);
              if (checkboxValues[questionText] != null &&
                  checkboxValues[questionText] == true) {
                print('yo its true');
                print(responses[questionText]);
              } else {
                print('well its false');
                print(responses[questionText]);
              }
              // updateCheckboxResponse(questionText, newValue);
            },
          ),
          Expanded(
            child: questionTextWithResponse(questionText, unit_, req),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              questionTextWithResponse(questionText, unit_, req),
              const SizedBox(height: 10),
              TextFormField(
                            controller: controllers[questionText],
                            maxLines: null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a value';
                              }
                              return null;
                            },
                          ),

              //_buildSmallTextField(questionText, 'Enter your answer', unit_),
            ],
          ),
        ),
      ),
    );
  }




@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Responses'),
      ),
      
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                const SizedBox(height: 20),
                if (questions.isEmpty)
                  const Text(
                    'No details are required',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20),
                  ),
                if (questions.isEmpty)
                  const SizedBox(
                    height: 20,
                  ),
                for (var question in questions) _buildQuestionWidget(question),
                
                
                ElevatedButton.icon(
                  onPressed: saveResponses,
                  icon: const Icon(Icons.save, size: 30),
                  label: const Text('Save Data'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }





  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text('Service Data'),
  //     ),
  //     body: SingleChildScrollView(
  //       child: Form(
  //         key: _formKey,
  //         child: Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: Column(
  //             children: [
  //               Column(
  //                 children: List.generate(entries.length, (index) {
  //                   final entry = entries[index];
  //                   final key = entry.key;
  //                   final value = entry.value.toString();
  //                   return Padding(
  //                     padding: const EdgeInsets.only(bottom: 16.0),
  //                     child: Column(
  //                       crossAxisAlignment: CrossAxisAlignment.start,
  //                       children: [
  //                         Text(
  //                           '${index + 1}. $key',
  //                           style: TextStyle(
  //                               fontSize: 16, fontWeight: FontWeight.bold),
  //                         ),
  //                         SizedBox(height: 8),
  //                         TextFormField(
  //                           controller: controllers[key],
  //                           maxLines: null,
  //                           decoration: InputDecoration(
  //                             border: OutlineInputBorder(),
  //                           ),
  //                           validator: (value) {
  //                             if (value == null || value.isEmpty) {
  //                               return 'Please enter a value';
  //                             }
  //                             return null;
  //                           },
  //                         ),
  //                       ],
  //                     ),
  //                   );
  //                 }),
  //               ),
  //               SizedBox(height: 16),
  //               ElevatedButton.icon(
  //                 onPressed: saveResponses,
  //                 icon: Icon(Icons.save, size: 30),
  //                 label: Text('Save Data'),
  //                 style: ElevatedButton.styleFrom(
  //                   padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //                   textStyle: TextStyle(fontSize: 16),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}