
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;


import 'app/ui/auth/auth_screen.dart';
import 'app/ui/home/HomeScreen.dart';

import 'firebase_options.dart';

void main() async{
  //flutter bindings must be initialized before calling async plugins
  WidgetsFlutterBinding.ensureInitialized();


  //Connect to your  firebase project using auto-generated config
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);



  //supabase storage Init(safe for mobile)
  await Supabase.initialize(
    url: 'https://kumjlnhmkwuadkxslagg.supabase.co',
    anonKey: 'sb_publishable_GRyJibABsxTzOyGpaBuyRQ_S62zy-NF',
  );


  //Initialize Hive and open a local box for GPS pings
  await Hive.initFlutter();
  await Hive.openBox('gps_pings');

  //This must be called before any Google Sign-In operations
  await GoogleSignIn.instance.initialize(
    clientId: null, //GoogleSignIn will auto-detect the correct clientId from firebase config
    serverClientId: null,
  );
  // TEMPORARY: Seed fake data ONCE
  //await seedSimple('Wq58Qs1vEDawW1WPENsTCCZLhJM2');
  //await seedMultiDayTrips('Wq58Qs1vEDawW1WPENsTCCZLhJM2');
  //await FirebaseFirestore.instance.clearPersistence();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    //GetMaterialApp is a wrapper around MaterialApp that provides GetX features like routing and state management.
    return GetMaterialApp(
      title: 'Driver Tracking App',
      theme: ThemeData(
        useMaterial3: true, brightness: Brightness.light),
      debugShowCheckedModeBanner: false,

      //AUTH GATE: Shows home if logged in, AuthScreen if not
      home: StreamBuilder<User?>(
        //authStateChanges() emits a new User? whenever login/logout happens
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot){
          //if user is authenticated  -> go to home
          if (snapshot.hasData){
            final user = snapshot.data!;

            //Block if email is not vrified
            if(!user.emailVerified){
              return AuthScreen();
            }
            return HomeScreen();
          }

            return AuthScreen();

          //AuthScreen is now imported.
          //return  AuthScreen();

        }

      ),

    );
  }
}

