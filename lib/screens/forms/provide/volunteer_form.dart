import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:covid_frontline/components/rounded_button.dart';
import 'package:dropdown_formfield/dropdown_formfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:covid_frontline/ui/nks_constants.dart';
import 'package:line_icons/line_icons.dart';

final _firestore = Firestore.instance;
final _auth = FirebaseAuth.instance;
FirebaseUser user;
String filledName,
    filledContact,
    region,
    subregion,
    filledAddress,
    volunteerFor,
    userId;

var volunteerApplications = {
  'name': filledName,
  'contact': filledContact,
  'state': region,
  'district': subregion,
  'address': filledAddress,
  'volunteerfor': volunteerFor,
  'uid': userId,
};

class VolunteerForm extends StatefulWidget {
  @override
  _VolunteerFormState createState() => _VolunteerFormState();
}

class _VolunteerFormState extends State<VolunteerForm> {
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
          title: Text('Apply to be a volunteer'),
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
                        hintText: 'What do you want to do as a volunteer?',
                        labelText: 'Volunteer For',
                        icon: Icon(
                          LineIcons.hand_o_up,
                          color: kFgcolor,
                        ),
                      ),
                      onChanged: (value) {
                        volunteerFor = value;
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
                    child: StateDropDown(),
                  ),
                  Container(
                    padding: EdgeInsets.all(8.0),
                    child: RoundedButton(
                        title: 'Submit',
                        onPressed: () {
                          _firestore
                              .collection('volunteer_applications')
                              .document(
                                  DateTime.now().toString() + '-' + userId)
                              .setData(volunteerApplications);
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

class StateDropDown extends StatefulWidget {
  @override
  _StateDropDownState createState() => _StateDropDownState();
}

class _StateDropDownState extends State<StateDropDown> {
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
