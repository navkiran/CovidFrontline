import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:covid_frontline/components/rounded_button.dart';
import 'package:dropdown_formfield/dropdown_formfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:covid_frontline/ui/nks_constants.dart';

final _firestore = Firestore.instance;
final _auth = FirebaseAuth.instance;
FirebaseUser user;
String filledName,
    filledContact,
    region,
    subregion,
    filledAddress,
    filledNeed,
    userId,
    job;

var jobs = [
  {
    "display": "Plumbing",
    "value": "Plumbing",
  },
  {
    "display": "Electricy/Electrical Appliances",
    "value": "Electricy/Electrical Appliances",
  }
];

var technicalServiceRequest = {
  'name': filledName,
  'contact': filledContact,
  'state': region,
  'district': subregion,
  'address': filledAddress,
  'need': filledNeed,
  'category': job,
  'uid': userId,
};

class TechnicalRequestForm extends StatefulWidget {
  @override
  _TechnicalRequestFormState createState() => _TechnicalRequestFormState();
}

class _TechnicalRequestFormState extends State<TechnicalRequestForm> {
  final _rationFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    user = await _auth.currentUser();
    userId = user.uid;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Request for Technical Service'),
          backgroundColor: kFgcolor,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Form(
              key: _rationFormKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      decoration: kFormTextFieldDecoration.copyWith(
                        hintText: 'Enter your name',
                        labelText: 'Name',
                        icon: Icon(
                          Icons.person,
                          color: kFgcolor,
                        ),
                      ),
                      onChanged: (value) {
                        filledName = value;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      keyboardType: TextInputType.phone,
                      decoration: kFormTextFieldDecoration.copyWith(
                        hintText: 'Enter your contact',
                        labelText: 'Contact',
                        icon: Icon(
                          Icons.phone,
                          color: kFgcolor,
                        ),
                      ),
                      onChanged: (value) {
                        filledContact = value;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                      minLines: 2,
                      decoration: kFormTextFieldDecoration.copyWith(
                        hintText:
                            'Please describe the issue you are facing - plumbing, electrical, etc.',
                        labelText: 'Technical Service Needed',
                        icon: Icon(
                          Icons.pan_tool,
                          color: kFgcolor,
                        ),
                      ),
                      onChanged: (value) {
                        filledNeed = value;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropDownFormField(
                      errorText: 'Please fill',
                      textField: 'display',
                      valueField: 'value',
                      titleText: 'Problem Category',
                      value: job,
                      onSaved: (value) {
                        setState(() {
                          job = value;
                        });
                      },
                      onChanged: (value) {
                        setState(() {
                          job = value;
                        });
                      },
                      dataSource: jobs,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                      minLines: 2,
                      decoration: kFormTextFieldDecoration.copyWith(
                        hintText: 'Enter your street address',
                        labelText: 'Street Address',
                        icon: Icon(
                          Icons.location_city,
                          color: kFgcolor,
                        ),
                      ),
                      onChanged: (value) {
                        filledAddress = value;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GroupedDropDown(),
                  ),
                  Container(
                    padding: EdgeInsets.all(8.0),
                    child: RoundedButton(
                        title: 'Submit',
                        onPressed: () {
                          _firestore
                              .collection('technical_service_requests')
                              .document(
                                  DateTime.now().toString() + '-' + userId)
                              .setData(technicalServiceRequest);
                          Navigator.pop(context);
                        }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GroupedDropDown extends StatefulWidget {
  @override
  _GroupedDropDownState createState() => _GroupedDropDownState();
}

class _GroupedDropDownState extends State<GroupedDropDown> {
  String sname;
  @override
  void initState() {
    super.initState();
    region = '';
    subregion = '';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('states').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.red,
              ),
            );
          }
          final documents = snapshot.data.documents;
          var _statesData = [];
          for (var document in documents) {
            _statesData.add(document.data['sname']);
          }

          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DropDownFormField(
                  errorText: 'Please fill the state where you are',
                  textField: 'display',
                  valueField: 'value',
                  titleText: 'State',
                  value: region,
                  onSaved: (value) {
                    setState(() {
                      region = value;
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      region = value;
                    });
                  },
                  dataSource: _statesData,
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                // region is the currently selected state, now we fetch district choices
                // each state has a list of districts
                // each element in states and then in list of districts is of map<string,string> type
                stream: _firestore
                    .collection("states")
                    .where("sname.value", isEqualTo: region)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  final documents = snapshot.data.documents;
                  var _districtData = [];
                  for (var document in documents) {
                    var districtsList = document.data['districts'];
                    for (var districtChoice in districtsList) {
                      _districtData.add(districtChoice);
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: DropDownFormField(
                      errorText: 'Please fill',
                      textField: 'display',
                      valueField: 'value',
                      titleText: 'District',
                      value: subregion,
                      onSaved: (value) {
                        setState(() {
                          subregion = value;
                        });
                      },
                      onChanged: (value) {
                        setState(() {
                          subregion = value;
                        });
                      },
                      dataSource: _districtData,
                    ),
                  );
                },
              )
            ],
          );
        });
  }
}
