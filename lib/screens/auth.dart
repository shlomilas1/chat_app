import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _fireBase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  bool _unAbleToLogin = false;
  bool _isUploading = false;

  final _formKey = GlobalKey<FormState>();

  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredUsername = '';
  File? _userImageFile;

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isLogin && _userImageFile == null) {
      return;
    }

    _formKey.currentState!.save();

    if (_isLogin) {
      print('trying to login');
      try {
        setState(() {
          _isUploading = true;
        });
        final UserCredential = await _fireBase
            .signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        )
            .then(
          (value) {
            print('logged in');
            setState(
              () {
                _unAbleToLogin = false;
                _isUploading = false;
              },
            );
          },
        );
        print(UserCredential);
      } on FirebaseAuthException catch (error) {
        switch (error.code) {
          case 'user-not-found':
            print('No user found for that email.');
            break;
          case 'wrong-password':
            print('Wrong password provided for that user.');
            break;
          default:
            print(error.message);
        }
        setState(() {
          _unAbleToLogin = true;
          _isUploading = false;
        });
      }
    } else {
      print('trying to sign up');
      try {
        setState(() {
          _isUploading = true;
        });
        _unAbleToLogin = false;
        final UserCredential = await _fireBase
            .createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        )
            .then((value) async {
          FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child(value.user!.uid + '.jpg')
              .putFile(_userImageFile!)
              .then((storageRef) {
            storageRef.ref.getDownloadURL().then((url) async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(value.user!.uid)
                  .set({
                'username': _enteredUsername,
                'email': _enteredEmail,
                'image_url': url,
              });
            });
          });
        });
        setState(
          () {
            _unAbleToLogin = false;
            _isUploading = false;
          },
        );
        print(UserCredential);
      } on FirebaseAuthException catch (error) {
        switch (error.code) {
          case 'email-already-in-use':
            print('The account already exists for that email.');
            break;
          case 'weak-password':
            print('The password provided is too weak.');
            break;
          default:
            print(error.message);
        }
        setState(() {
          _unAbleToLogin = true;
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('is login: $_isLogin');
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  bottom: 20,
                  top: 30,
                  left: 20,
                  right: 20,
                ),
                width: 200,
                child: Image.asset('assets/images/chat.png'),
              ),
              Card(
                  margin: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _unAbleToLogin
                                ? const Text(
                                    'unable to log in.',
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  )
                                : const SizedBox(),
                            if (!_isLogin)
                              UserImagePicker(
                                onPickedImage: (pickedImage) {
                                  _userImageFile = pickedImage;
                                },
                              ),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Email',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    !value.contains('@')) {
                                  return 'Please enter a valid email address.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredEmail = value!;
                              },
                            ),
                            if (!_isLogin)
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                textCapitalization: TextCapitalization.none,
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().length < 4 ||
                                      value.isEmpty) {
                                    return 'Please enter a valid user name.';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _enteredUsername = value!;
                                },
                              ),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Password',
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.trim().length < 6) {
                                  return 'Password must be at least 6 characters long.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredPassword = value!;
                              },
                            ),
                            const SizedBox(height: 12),
                            _isUploading
                                ? SizedBox(
                                    height: 32,
                                    width: 32,
                                    child: CircularProgressIndicator(),
                                  )
                                : ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                    ),
                                    child: Text(_isLogin ? 'Login' : 'Signup'),
                                  ),
                            if (!_isUploading)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                                child: Text(_isLogin
                                    ? 'Create new account'
                                    : 'I already have an account'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
