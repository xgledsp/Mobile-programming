import 'package:flutter/material.dart';
import 'me_models.dart'; // [저장 기능 추가]
// 캘린더에 추가한 일정 정보 집합인 eventStore를 쓰기 위해
import 'onboarding.dart';

// [수정] main()을 async로 바꿨어요.
// 앱 화면을 띄우기 전에, 기기에 저장해 둔 캘린더 일정을 먼저 불러와요.
// 그래서 Me 탭을 열면 지난번에 저장한 일정이 바로 보여요.
Future<void> main() async {
  // [저장 기능 추가] runApp() 전에 shared_preferences 같은 플러그인을 쓰려면
  // Flutter 엔진을 먼저 준비시켜야 해요.
  WidgetsFlutterBinding.ensureInitialized();

  // [저장 기능 추가] 저장된 일정 불러오기 (첫 실행(일정 추가 X)이면 빈 캘린더).
  await eventStore.load();

  runApp(const SouthKoreaApp());
}
