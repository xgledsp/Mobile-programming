import '../topic_guard.dart';
import 'kb_entry.dart';

// ================================================================
// HODU KNOWLEDGE BASE - prepared answers that work OFFLINE
// ================================================================
//
// Written for international students (mostly D-2 / D-4 visas).
// Rules, fees and deadlines change, so answers give the general steps
// and always point to an official source instead of exact numbers that
// may be outdated. Last reviewed: 2026-11.
//
// To add an entry: copy one block, give it a new unique id, write both
// languages and add keywords a student would really type.
// ================================================================

const List<KbEntry> hoduKnowledgeBase = [
  // ------------------------------------------------------------ visa
  KbEntry(
    id: 'arc_apply',
    category: TopicCategory.visa,
    questionEn: 'How do I get my ARC (alien registration card)?',
    questionKo: '외국인등록증(ARC)은 어떻게 받나요?',
    keywords: [
      'arc', 'alien registration', 'residence card', 'register', 'registration',
      'immigration office', 'hikorea', 'reservation',
      '외국인등록', '외국인 등록', '등록증', '출입국', '외국인관서', '예약',
    ],
    answerEn: 'If you stay in Korea longer than 90 days you must register for an ARC '
        '(외국인등록증) within 90 days of arriving.\n'
        '• Book a visit at your local immigration office on HiKorea.\n'
        '• Bring: passport, application form, one passport photo, the fee, '
        'your certificate of enrollment and proof of address (e.g. dorm certificate or lease).\n'
        '• Many universities help with a group application — ask your international office first.\n'
        'The card usually arrives a few weeks later.',
    answerKo: '한국에 90일 넘게 머무르면 입국 후 90일 안에 외국인등록을 해야 해요.\n'
        '• 하이코리아에서 관할 출입국·외국인관서 방문 예약을 하세요.\n'
        '• 준비물: 여권, 신청서, 여권용 사진 1장, 수수료, 재학증명서, '
        '거주지 증빙(기숙사 확인서나 임대차계약서 등)\n'
        '• 학교 국제처에서 단체 신청을 도와주는 경우가 많으니 먼저 물어보세요.\n'
        '카드는 보통 몇 주 후에 나와요.',
    sourceEn: 'HiKorea (hikorea.go.kr) / Immigration Contact Center 1345',
    sourceKo: '하이코리아(hikorea.go.kr) / 외국인종합안내센터 1345',
  ),
  KbEntry(
    id: 'visa_extend',
    category: TopicCategory.visa,
    questionEn: 'How do I extend my student visa?',
    questionKo: '학생 비자는 어떻게 연장하나요?',
    keywords: [
      'extend', 'extension', 'expire', 'expires', 'expiry', 'expiration', 'renew',
      'period of stay', 'd-2', 'd2', 'd-4', 'd4', 'student visa',
      '연장', '만료', '체류기간', '체류 기간', '갱신',
    ],
    answerEn: 'Apply for an extension of stay (체류기간 연장) BEFORE the date on your ARC expires — '
        'staying even one day late can mean a fine.\n'
        '• Apply online on HiKorea (e-application) or book a visit at the immigration office.\n'
        '• Usually needed: passport, ARC, certificate of enrollment, transcript, '
        'proof of funds or tuition payment, and proof of address.\n'
        '• Your school may need to confirm your attendance, so ask the international office early.',
    answerKo: '외국인등록증에 적힌 체류기간이 끝나기 전에 체류기간 연장을 신청해야 해요. '
        '하루라도 늦으면 범칙금이 나올 수 있어요.\n'
        '• 하이코리아 전자민원으로 신청하거나 출입국·외국인관서 방문 예약을 하세요.\n'
        '• 보통 필요한 서류: 여권, 외국인등록증, 재학증명서, 성적증명서, '
        '재정 증빙이나 등록금 납부 확인서, 거주지 증빙\n'
        '• 학교 확인이 필요할 수 있으니 국제처에 미리 물어보세요.',
    sourceEn: 'HiKorea (hikorea.go.kr) / 1345',
    sourceKo: '하이코리아(hikorea.go.kr) / 1345',
  ),
  KbEntry(
    id: 'address_change',
    category: TopicCategory.visa,
    questionEn: 'I moved. Do I need to report my new address?',
    questionKo: '이사했어요. 주소 변경 신고를 해야 하나요?',
    keywords: [
      'moved', 'move', 'new address', 'change address', 'address change', 'report address',
      '이사', '주소 변경', '주소변경', '체류지 변경', '체류지변경', '전입신고',
    ],
    answerEn: 'Yes. Foreigners with an ARC must report a new address within about two weeks of '
        'moving (체류지 변경신고) — check the exact deadline on HiKorea.\n'
        '• You can do it online on HiKorea, at the community service center (주민센터) '
        'of your new area, or at the immigration office.\n'
        '• Bring your ARC, passport and proof of the new address (lease or dorm certificate).\n'
        'Reporting late can lead to a fine.',
    answerKo: '네. 외국인등록증이 있으면 이사 후 약 2주 안에 체류지 변경신고를 해야 해요. 정확한 기한은 하이코리아에서 확인하세요.\n'
        '• 하이코리아 온라인, 새 주소지의 주민센터, 또는 출입국·외국인관서에서 할 수 있어요.\n'
        '• 외국인등록증, 여권, 새 주소 증빙(임대차계약서나 기숙사 확인서)을 가져가세요.\n'
        '늦게 신고하면 과태료가 나올 수 있어요.',
    sourceEn: 'HiKorea (hikorea.go.kr) / 1345',
    sourceKo: '하이코리아(hikorea.go.kr) / 1345',
  ),

  // ------------------------------------------------------------ work
  KbEntry(
    id: 'part_time_work',
    category: TopicCategory.work,
    questionEn: 'Can I work a part-time job on a student visa?',
    questionKo: '학생 비자로 아르바이트를 할 수 있나요?',
    keywords: [
      'part time', 'part-time', 'job', 'work', 'working', 'arbeit', 'alba',
      'work permit', 'permission', 'hours',
      '아르바이트', '알바', '일하', '시간제취업', '시간제 취업', '취업 허가', '근무 시간',
    ],
    answerEn: 'Yes, but only WITH permission first. D-2/D-4 students must get part-time work '
        'permission (시간제취업 허가) from immigration before starting the job.\n'
        '• Your school\'s international office usually has to confirm it first.\n'
        '• Weekly hours are limited and depend on your Korean level (TOPIK), grades and '
        'whether it is vacation.\n'
        '• Working without permission can lead to fines or losing your visa.',
    answerKo: '할 수 있지만 먼저 허가를 받아야 해요. D-2/D-4 학생은 일을 시작하기 전에 '
        '출입국에서 시간제취업 허가를 받아야 해요.\n'
        '• 보통 학교 국제처 확인이 먼저 필요해요.\n'
        '• 주당 근무 시간은 제한이 있고, 한국어 능력(TOPIK), 성적, 방학 여부에 따라 달라요.\n'
        '• 허가 없이 일하면 범칙금을 내거나 비자에 문제가 생길 수 있어요.',
    sourceEn: 'HiKorea / your international office / 1345',
    sourceKo: '하이코리아 / 학교 국제처 / 1345',
  ),
  KbEntry(
    id: 'wage_problem',
    category: TopicCategory.work,
    questionEn: 'My employer did not pay my wage. What can I do?',
    questionKo: '사장님이 월급을 안 줬어요. 어떻게 해야 하나요?',
    keywords: [
      'not paid', 'unpaid', "didn't pay", 'did not pay', 'wage', 'salary', 'minimum wage',
      'employer', 'boss', 'labor', 'labour',
      '월급', '임금', '시급', '최저임금', '체불', '안 줬', '안줬', '사장님', '노동',
    ],
    answerEn: 'Foreign workers, including students with work permission, are protected by Korean '
        'labor law and the minimum wage.\n'
        '• Keep proof: contract, messages, work schedule, bank records.\n'
        '• Ask the employer politely in writing first.\n'
        '• If they still do not pay, you can report unpaid wages (임금체불) to the Ministry of '
        'Employment and Labor — call 1350 (interpretation available).',
    answerKo: '시간제취업 허가를 받은 학생을 포함한 외국인 노동자도 근로기준법과 '
        '최저임금의 보호를 받아요.\n'
        '• 증거를 모아 두세요: 근로계약서, 메시지, 근무표, 입금 내역\n'
        '• 먼저 사장님께 문자 등 기록이 남는 방법으로 정중하게 요청하세요.\n'
        '• 그래도 안 주면 고용노동부에 임금체불 신고를 할 수 있어요. 1350으로 전화하세요.',
    sourceEn: 'Ministry of Employment and Labor 1350',
    sourceKo: '고용노동부 고객상담센터 1350',
  ),

  // ------------------------------------------------------------ housing
  KbEntry(
    id: 'dorm_check_in',
    category: TopicCategory.housing,
    questionEn: 'What do I need to move into the dormitory?',
    questionKo: '기숙사 입주할 때 뭐가 필요해요?',
    keywords: [
      'dorm', 'dormitory', 'check in', 'check-in', 'move in', 'room key', 'bring',
      '기숙사', '입주', '입사', '체크인', '준비물',
    ],
    answerEn: 'Each university has its own rules, but students usually need:\n'
        '• Passport (and ARC if you already have one)\n'
        '• Dorm acceptance / check-in confirmation (입주 확인서)\n'
        '• Receipt for the dorm fee\n'
        '• Often a health certificate, e.g. a tuberculosis (TB) test result\n'
        'Check the dorm office opening hours and your check-in date in the dorm notice '
        'before you go.',
    answerKo: '학교마다 규칙이 다르지만 보통 이런 게 필요해요.\n'
        '• 여권 (외국인등록증이 있으면 함께)\n'
        '• 기숙사 합격/입주 확인서\n'
        '• 기숙사비 납부 영수증\n'
        '• 결핵 검사 결과 같은 건강진단서가 필요한 경우가 많아요\n'
        '가기 전에 기숙사 공지에서 입주 날짜와 행정실 운영 시간을 확인하세요.',
    sourceEn: 'Your dormitory office notice',
    sourceKo: '학교 기숙사 행정실 공지',
  ),
  KbEntry(
    id: 'renting_deposit',
    category: TopicCategory.housing,
    questionEn: 'How does renting a room (월세 / 전세) work, and how do I protect my deposit?',
    questionKo: '월세나 전세는 어떻게 하고, 보증금은 어떻게 지키나요?',
    keywords: [
      'rent', 'renting', 'one room', 'oneroom', 'apartment', 'deposit', 'lease', 'contract',
      'landlord', 'jeonse', 'wolse', 'real estate',
      '월세', '전세', '보증금', '원룸', '계약', '집주인', '부동산', '등기부등본', '확정일자',
    ],
    answerEn: 'Two common types:\n'
        '• 월세 (wolse): a deposit (보증금) plus monthly rent.\n'
        '• 전세 (jeonse): one large deposit and no monthly rent.\n'
        'To protect your deposit:\n'
        '• Before signing, check the property register (등기부등본) to see the real owner '
        'and existing loans.\n'
        '• Sign the contract with the real owner and keep a copy.\n'
        '• After moving in, report your address and get a fixed date (확정일자) on the '
        'contract at the community service center.\n'
        'Ask a Korean friend or your school to read the contract with you.',
    answerKo: '대표적인 두 가지가 있어요.\n'
        '• 월세: 보증금 + 매달 내는 월세\n'
        '• 전세: 큰 보증금만 내고 월세는 없음\n'
        '보증금을 지키려면:\n'
        '• 계약 전에 등기부등본으로 실제 집주인과 대출(근저당)을 확인하세요.\n'
        '• 실제 집주인과 계약하고 계약서 사본을 꼭 보관하세요.\n'
        '• 입주 후 주민센터에서 주소 신고를 하고 계약서에 확정일자를 받으세요.\n'
        '계약서는 한국인 친구나 학교에 같이 봐 달라고 부탁하세요.',
    sourceEn: 'Your community service center (주민센터) / school international office',
    sourceKo: '주민센터 / 학교 국제처',
  ),

  // ------------------------------------------------------------ banking
  KbEntry(
    id: 'bank_account',
    category: TopicCategory.banking,
    questionEn: 'How do I open a bank account in Korea?',
    questionKo: '한국에서 은행 계좌는 어떻게 만드나요?',
    keywords: [
      'bank', 'bank account', 'open an account', 'account', 'debit card', 'check card',
      'atm', 'transfer limit',
      '은행', '계좌', '통장', '체크카드', '계좌 개설', '계좌개설', '한도',
    ],
    answerEn: 'Go to a bank branch (many have branches on or near campus).\n'
        '• Bring: passport, ARC (most banks need it), certificate of enrollment or student ID, '
        'and a Korean phone number.\n'
        '• Tell them the purpose, e.g. "for tuition and daily life".\n'
        '• New accounts often have a daily transfer limit (한도제한계좌) at first; it can be '
        'raised later with proof like a work or school document.\n'
        'Ask for a check card (체크카드) and mobile banking at the same time.',
    answerKo: '은행 지점에 직접 가세요. 캠퍼스 안이나 근처에 지점이 있는 경우가 많아요.\n'
        '• 준비물: 여권, 외국인등록증(대부분 필요), 재학증명서나 학생증, 한국 휴대폰 번호\n'
        '• 사용 목적을 말하세요. 예: "등록금과 생활비용이에요."\n'
        '• 처음에는 이체 한도가 있는 한도제한계좌로 만들어지는 경우가 많고, '
        '나중에 서류를 내면 한도를 올릴 수 있어요.\n'
        '체크카드와 모바일 뱅킹도 같이 신청하세요.',
    sourceEn: 'The bank branch',
    sourceKo: '은행 지점',
  ),
  KbEntry(
    id: 'send_money_home',
    category: TopicCategory.banking,
    questionEn: 'How can I send money abroad or exchange money?',
    questionKo: '해외 송금이나 환전은 어떻게 하나요?',
    keywords: [
      'send money', 'money transfer', 'overseas transfer', 'remittance', 'exchange money',
      'currency exchange', 'exchange rate', 'wise',
      '송금', '해외송금', '해외 송금', '환전', '환율',
    ],
    answerEn: '• Exchange money at banks or licensed money exchange shops; airports usually give '
        'worse rates.\n'
        '• To send money abroad, use your bank\'s overseas remittance service or a licensed '
        'remittance app. Compare the fee and the exchange rate.\n'
        '• Banks may limit overseas transfers for new foreign customers and ask for documents.\n'
        'Never send money for someone you do not know — it may be a scam.',
    answerKo: '• 환전은 은행이나 정식 환전소에서 하세요. 공항은 보통 환율이 좋지 않아요.\n'
        '• 해외 송금은 은행 해외송금 서비스나 정식 등록된 송금 앱을 쓰세요. '
        '수수료와 환율을 비교해 보세요.\n'
        '• 새로 온 외국인 고객은 해외 송금 한도가 있거나 서류를 요구받을 수 있어요.\n'
        '모르는 사람을 위해 돈을 보내지 마세요. 사기일 수 있어요.',
    sourceEn: 'Your bank',
    sourceKo: '거래 은행',
  ),

  // ------------------------------------------------------------ phone
  KbEntry(
    id: 'sim_card',
    category: TopicCategory.phone,
    questionEn: 'How do I get a SIM card and a phone plan?',
    questionKo: '유심과 휴대폰 요금제는 어떻게 만드나요?',
    keywords: [
      'sim', 'sim card', 'usim', 'esim', 'phone plan', 'mobile plan', 'phone number',
      'carrier', 'prepaid', 'postpaid', 'skt', 'kt', 'lg u+', 'mvno', 'data',
      '유심', '요금제', '통신사', '휴대폰', '핸드폰', '전화번호', '알뜰폰', '선불', '후불',
    ],
    answerEn: 'Two main options:\n'
        '• Prepaid (선불): possible with just your passport. Good for your first weeks.\n'
        '• Monthly plan (후불): usually needs your ARC.\n'
        'The big carriers are SKT, KT and LG U+. Budget carriers (알뜰폰 / MVNO) use the same '
        'networks and are often much cheaper.\n'
        'A Korean phone number is needed for banking apps, delivery apps and many sign-ups, '
        'so get one early.',
    answerKo: '크게 두 가지가 있어요.\n'
        '• 선불 요금제: 여권만으로 가능해요. 처음 몇 주 동안 쓰기 좋아요.\n'
        '• 후불(월정액) 요금제: 보통 외국인등록증이 필요해요.\n'
        '주요 통신사는 SKT, KT, LG U+이고, 알뜰폰은 같은 망을 쓰면서 훨씬 싼 경우가 많아요.\n'
        '은행 앱, 배달 앱, 각종 가입에 한국 번호가 필요하니 빨리 만드세요.',
  ),

  // ------------------------------------------------------------ school
  KbEntry(
    id: 'add_drop',
    category: TopicCategory.school,
    questionEn: 'What is the add/drop period and how do I change my classes?',
    questionKo: '수강신청 정정 기간이 뭐고, 수업은 어떻게 바꾸나요?',
    keywords: [
      'add/drop', 'add drop', 'add or drop', 'drop a class', 'change class', 'course registration',
      'withdraw', 'withdrawal', 'enroll', 'enrollment', 'class', 'course',
      '수강신청', '수강 신청', '정정', '철회', '수강 취소', '수강취소', '수업 변경',
    ],
    answerEn: '• Course registration (수강신청) happens before the semester on the student portal.\n'
        '• The add/drop period (수강신청 정정) is usually in the first week of the semester: '
        'you can freely add or drop classes on the portal.\n'
        '• After that there is often a withdrawal period (수강철회) where you can still drop a '
        'class, but it may show on your record.\n'
        'Exact dates are in your school notice — the Notice Explained tab can help you read it, '
        'and you can add the deadline to your calendar.',
    answerKo: '• 수강신청은 학기 시작 전에 학교 포털에서 해요.\n'
        '• 수강신청 정정 기간은 보통 개강 첫 주예요. 포털에서 자유롭게 과목을 추가하거나 '
        '삭제할 수 있어요.\n'
        '• 그 후에 수강철회 기간이 있는 경우가 많아요. 과목을 취소할 수 있지만 '
        '기록에 남을 수 있어요.\n'
        '정확한 날짜는 학교 공지에 있어요. 공지 해설 탭에서 읽는 걸 도와줄 수 있고, '
        '마감일을 캘린더에 추가할 수도 있어요.',
    sourceEn: 'Your university academic notice',
    sourceKo: '학교 학사 공지',
  ),
  KbEntry(
    id: 'international_office',
    category: TopicCategory.school,
    questionEn: 'Who can help me at my university?',
    questionKo: '학교에서 누구한테 도움을 받을 수 있나요?',
    keywords: [
      'international office', 'office of international affairs', 'who can help', 'student support',
      'certificate', 'certificate of enrollment', 'transcript', 'buddy', 'who can help',
      'help me', 'my university', 'my school',
      '국제처', '국제교류처', '국제팀', '재학증명서', '성적증명서', '증명서', '버디', '도움',
      '누구한테', '누구에게',
    ],
    answerEn: 'Start with your international office (국제처 / 국제교류처). They help with visas, '
        'ARC group applications, part-time work permission, dorms and insurance.\n'
        '• Certificates (재학증명서, 성적증명서) can usually be printed from the student portal or '
        'a certificate machine on campus.\n'
        '• Many schools have a buddy program that pairs you with a Korean student — ask about it!',
    answerKo: '먼저 학교 국제처(국제교류처)에 가 보세요. 비자, 외국인등록 단체 신청, '
        '시간제취업 허가, 기숙사, 보험 등을 도와줘요.\n'
        '• 재학증명서와 성적증명서는 보통 학교 포털이나 캠퍼스의 증명서 발급기에서 뽑을 수 있어요.\n'
        '• 한국 학생과 연결해 주는 버디 프로그램이 있는 학교가 많으니 물어보세요!',
  ),

  // ------------------------------------------------------------ health
  KbEntry(
    id: 'health_insurance',
    category: TopicCategory.health,
    questionEn: 'Do I need health insurance in Korea?',
    questionKo: '한국에서 건강보험에 가입해야 하나요?',
    keywords: [
      'health insurance', 'insurance', 'nhis', 'national health insurance', 'premium',
      'insurance bill',
      '건강보험', '보험', '보험료', '국민건강보험', '건보',
    ],
    answerEn: 'Yes. International students staying long-term are generally enrolled in the '
        'National Health Insurance (국민건강보험) and pay a monthly premium.\n'
        '• With it you pay only part of the cost at hospitals and pharmacies.\n'
        '• The bill comes by mail or app — pay it on time, because unpaid premiums can cause '
        'problems when you extend your visa.\n'
        '• Some schools also require extra private insurance.',
    answerKo: '네. 장기 체류하는 유학생은 보통 국민건강보험에 가입되고 매달 보험료를 내요.\n'
        '• 보험이 있으면 병원과 약국에서 비용의 일부만 내요.\n'
        '• 고지서는 우편이나 앱으로 와요. 보험료를 안 내면 체류기간 연장 때 '
        '문제가 될 수 있으니 제때 내세요.\n'
        '• 학교에 따라 별도 유학생 보험이 필요할 수도 있어요.',
    sourceEn: 'NHIS 1577-1000 (foreign language service available)',
    sourceKo: '국민건강보험공단 1577-1000',
  ),
  KbEntry(
    id: 'hospital_pharmacy',
    category: TopicCategory.health,
    questionEn: 'I am sick. Where should I go?',
    questionKo: '아파요. 어디로 가야 하나요?',
    keywords: [
      'sick', 'ill', 'fever', 'cold', 'flu', 'doctor', 'hospital', 'clinic', 'pharmacy',
      'medicine', 'headache', 'stomach',
      '아파', '아프', '감기', '열이', '병원', '의원', '약국', '약을', '진료', '두통', '배탈',
    ],
    answerEn: '• For a cold, fever or small problems, visit a local clinic (의원) — no appointment '
        'is usually needed. Internal medicine is 내과.\n'
        '• Bring your ARC or passport so your health insurance is applied.\n'
        '• The doctor gives a prescription; take it to a pharmacy (약국) nearby.\n'
        '• For simple medicine (painkillers, cold medicine) you can go to a pharmacy directly.\n'
        'In an emergency call 119.',
    answerKo: '• 감기, 열, 가벼운 증상이면 동네 의원에 가세요. 보통 예약 없이 갈 수 있어요. '
        '일반적인 증상은 내과로 가면 돼요.\n'
        '• 건강보험이 적용되도록 외국인등록증이나 여권을 가져가세요.\n'
        '• 의사가 처방전을 주면 근처 약국에 가져가세요.\n'
        '• 진통제나 감기약 같은 간단한 약은 약국에서 바로 살 수 있어요.\n'
        '응급 상황이면 119에 전화하세요.',
  ),

  // ------------------------------------------------------------ transport
  KbEntry(
    id: 'transport_card',
    category: TopicCategory.transport,
    questionEn: 'How do I use the bus and subway?',
    questionKo: '버스와 지하철은 어떻게 타요?',
    keywords: [
      'bus', 'subway', 'metro', 'transportation card', 'transport card', 't-money', 'tmoney',
      'transfer', 'top up', 'charge card',
      '버스', '지하철', '교통카드', '티머니', '환승', '충전',
    ],
    answerEn: '• Buy a transportation card (교통카드, e.g. T-money) at a convenience store and top '
        'it up with cash there or at subway machines. Many Korean check cards also work as '
        'transport cards.\n'
        '• Tap the card when you get on AND when you get off the bus — then transfers within '
        'a short time are free or discounted.\n'
        '• Map apps like Naver Map or KakaoMap show routes and bus arrival times better '
        'than Google Maps in Korea.',
    answerKo: '• 편의점에서 티머니 같은 교통카드를 사고, 편의점이나 지하철역 기계에서 현금으로 '
        '충전하세요. 교통카드 기능이 있는 체크카드도 많아요.\n'
        '• 버스는 탈 때와 내릴 때 모두 카드를 찍어야 환승 할인을 받을 수 있어요.\n'
        '• 한국에서는 구글 지도보다 네이버 지도나 카카오맵이 길찾기와 버스 도착 정보가 더 정확해요.',
  ),

  // ------------------------------------------------------------ daily life
  KbEntry(
    id: 'trash_sorting',
    category: TopicCategory.dailyLife,
    questionEn: 'How do I throw away trash in Korea?',
    questionKo: '한국에서는 쓰레기를 어떻게 버려요?',
    keywords: [
      'trash', 'garbage', 'rubbish', 'recycle', 'recycling', 'food waste', 'trash bag',
      'waste',
      '쓰레기', '분리수거', '분리배출', '음식물', '종량제', '재활용',
    ],
    answerEn: 'Korea sorts trash strictly:\n'
        '• General trash goes in official pay-as-you-throw bags (종량제 봉투) from a convenience '
        'store or mart — buy the bags for your district.\n'
        '• Food waste (음식물 쓰레기) is separate, in a food-waste bag or bin.\n'
        '• Recyclables (plastic, cans, glass, paper) are rinsed and sorted.\n'
        'Days, places and rules differ by building and district, so check the notice in your '
        'building or ask the manager. Wrong disposal can be fined.',
    answerKo: '한국은 쓰레기를 엄격하게 분리해요.\n'
        '• 일반 쓰레기는 편의점이나 마트에서 파는 종량제 봉투에 버려요. 사는 지역(구) 봉투를 사세요.\n'
        '• 음식물 쓰레기는 따로 음식물 봉투나 수거함에 버려요.\n'
        '• 플라스틱, 캔, 유리, 종이 같은 재활용품은 씻어서 분리해요.\n'
        '버리는 요일과 장소는 건물과 지역마다 다르니 건물 공지를 보거나 관리인께 물어보세요. '
        '잘못 버리면 과태료가 나올 수 있어요.',
  ),
  KbEntry(
    id: 'lost_item',
    category: TopicCategory.emergency,
    questionEn: 'I lost my wallet / phone / ARC. What should I do?',
    questionKo: '지갑/휴대폰/외국인등록증을 잃어버렸어요. 어떻게 하죠?',
    keywords: [
      'lost', 'lost my', 'lost and found', 'missing', 'stolen', 'left my', 'wallet',
      'lost phone', 'lost card', 'phone', 'stolen phone',
      '잃어버', '분실', '도난', '두고 내렸', '지갑', '유실물', '휴대폰', '핸드폰', '재발급',
    ],
    answerEn: '• Check the police lost-and-found site lost112.go.kr — items found in taxis, '
        'subways and shops are often registered there.\n'
        '• For the subway or bus, contact the station or bus company lost-and-found.\n'
        '• Lost bank card: call your bank right away to block it.\n'
        '• Lost ARC: report it and apply for a new card at the immigration office '
        'as soon as possible.\n'
        '• If something was stolen, report it to the police (112).',
    answerKo: '• 경찰청 유실물 사이트 lost112.go.kr을 확인하세요. 택시, 지하철, 가게에서 '
        '찾은 물건이 많이 등록돼요.\n'
        '• 지하철이나 버스에 두고 내렸으면 역이나 버스 회사 유실물 센터에 연락하세요.\n'
        '• 은행 카드를 잃어버렸으면 바로 은행에 전화해서 정지하세요.\n'
        '• 외국인등록증을 잃어버렸으면 출입국·외국인관서에서 분실 신고 후 재발급을 '
        '최대한 빨리 신청하세요.\n'
        '• 도난이면 경찰(112)에 신고하세요.',
    sourceEn: 'lost112.go.kr / police 112 / 1345',
    sourceKo: 'lost112.go.kr / 경찰 112 / 1345',
  ),
  KbEntry(
    id: 'emergency_numbers',
    category: TopicCategory.emergency,
    questionEn: 'What numbers do I call in an emergency?',
    questionKo: '긴급할 때 몇 번으로 전화해요?',
    keywords: [
      'emergency', 'police', 'ambulance', 'fire', 'help number', 'phone number for',
      'interpreter', 'interpretation', 'accident', 'danger',
      '응급', '긴급', '경찰', '구급차', '119', '112', '통역', '사고', '위험', '신고',
    ],
    answerEn: '• 112 — Police (crime, danger, lost children)\n'
        '• 119 — Fire and ambulance (medical emergency)\n'
        '• 1345 — Immigration Contact Center for foreigners (many languages)\n'
        '• 1330 — Korea travel hotline with interpretation\n'
        'If you cannot explain in Korean, say your language in English (e.g. "English, please") '
        '— 112 and 119 can connect an interpreter.',
    answerKo: '• 112 — 경찰 (범죄, 위험한 상황, 미아)\n'
        '• 119 — 소방·구급 (응급 환자)\n'
        '• 1345 — 외국인종합안내센터 (여러 언어 지원)\n'
        '• 1330 — 관광 통역 안내 전화\n'
        '한국어로 설명하기 어려우면 사용하는 언어를 말하세요. 112와 119는 통역을 연결해 줄 수 있어요.',
  ),
  KbEntry(
    id: 'phone_scam',
    category: TopicCategory.emergency,
    questionEn: 'Someone called saying they are police / immigration and asked for money. Is it a scam?',
    questionKo: '경찰이나 출입국이라며 돈을 요구하는 전화가 왔어요. 사기인가요?',
    keywords: [
      'scam', 'fraud', 'phishing', 'voice phishing', 'suspicious call', 'fake police',
      'asked for money', 'asking for money', 'someone called', 'called me', 'call from',
      '사기', '보이스피싱', '피싱', '수상한 전화', '돈을 보내', '송금 요구', '돈을 요구', '전화가 왔',
      '경찰이라', '출입국이라', '검찰',
    ],
    answerEn: 'Very likely yes — this is called voice phishing (보이스피싱).\n'
        '• Real police, prosecutors, immigration or banks NEVER ask you to send money, '
        'buy gift cards or give passwords on the phone.\n'
        '• Hang up. Do not install apps they send.\n'
        '• If you already sent money, call 112 and your bank immediately to stop the payment.',
    answerKo: '사기일 가능성이 매우 높아요. 이런 걸 보이스피싱이라고 해요.\n'
        '• 진짜 경찰, 검찰, 출입국, 은행은 전화로 송금, 상품권 구매, 비밀번호를 절대 요구하지 않아요.\n'
        '• 전화를 끊고, 보내 준 앱은 설치하지 마세요.\n'
        '• 이미 돈을 보냈다면 바로 112와 은행에 전화해서 지급 정지를 요청하세요.',
    sourceEn: 'Police 112',
    sourceKo: '경찰 112',
  ),

  // ------------------------------------------------------------ culture
  KbEntry(
    id: 'honorifics_age',
    category: TopicCategory.culture,
    questionEn: 'Why do Koreans ask my age, and when should I use polite language?',
    questionKo: '한국 사람들은 왜 나이를 묻고, 존댓말은 언제 써요?',
    keywords: [
      'age', 'how old', 'polite', 'politeness', 'honorific', 'honorifics', 'formal',
      'informal', 'banmal', 'jondaetmal', 'senior', 'sunbae', 'rude', 'unnie', 'oppa',
      '나이', '존댓말', '반말', '선배', '후배', '언니', '오빠', '누나', '예의', '실례',
    ],
    answerEn: 'In Korea, age and seniority decide how people speak to each other, so asking '
        'your age is normal, not rude.\n'
        '• Use polite speech (존댓말, ending in -요) with strangers, staff, professors and '
        'anyone older or more senior.\n'
        '• Switch to casual speech (반말) only when the other person suggests it '
        '(e.g. "말 놓으세요" / "you can speak comfortably").\n'
        '• Younger students may call older friends 언니/누나 (older sister) or '
        '오빠/형 (older brother) — it shows closeness.',
    answerKo: '한국에서는 나이와 선후배 관계에 따라 말투가 달라서 나이를 묻는 건 '
        '무례한 게 아니라 자연스러운 일이에요.\n'
        '• 처음 만난 사람, 직원, 교수님, 나보다 나이가 많거나 선배인 사람에게는 '
        '존댓말(-요)을 쓰세요.\n'
        '• 상대가 "말 놓으세요"라고 하면 그때 반말을 써도 돼요.\n'
        '• 어린 학생은 나이 많은 친구를 언니/누나, 오빠/형이라고 부르기도 해요. '
        '친하다는 뜻이에요.',
  ),
  KbEntry(
    id: 'dining_drinking',
    category: TopicCategory.culture,
    questionEn: 'What should I know about eating and drinking with Koreans?',
    questionKo: '한국 사람과 밥 먹거나 술 마실 때 알아야 할 예절이 있나요?',
    keywords: [
      'table manners', 'eating', 'dinner', 'drinking', 'drink', 'alcohol', 'soju',
      'pour', 'company dinner', 'hoesik', 'tipping', 'tip', 'chopsticks',
      '회식', '술자리', '술', '소주', '식사 예절', '밥 먹', '팁', '젓가락', '건배',
    ],
    answerEn: '• Wait for the oldest person to start eating first.\n'
        '• Use two hands (or support your arm) when giving or receiving something from an elder, '
        'including pouring drinks.\n'
        '• When drinking with an older person, it is polite to turn your head slightly away.\n'
        '• You never have to drink alcohol — saying "I don\'t drink" (술 못 마셔요) or '
        'choosing a soft drink is fine.\n'
        '• Tipping is not expected in Korea.',
    answerKo: '• 가장 나이 많은 사람이 먼저 수저를 들면 먹기 시작하세요.\n'
        '• 어른에게 물건을 주거나 받을 때, 술을 따를 때는 두 손으로 하세요.\n'
        '• 윗사람과 술을 마실 때는 고개를 살짝 옆으로 돌리는 게 예의예요.\n'
        '• 술은 꼭 마시지 않아도 돼요. "술 못 마셔요"라고 하거나 음료수를 마셔도 괜찮아요.\n'
        '• 한국에서는 팁 문화가 없어요.',
  ),

  // ------------------------------------------------------------ language
  KbEntry(
    id: 'useful_phrases',
    category: TopicCategory.language,
    questionEn: 'What are some useful Korean phrases for daily life?',
    questionKo: '생활에 유용한 한국어 표현을 알려 주세요.',
    keywords: [
      'useful phrases', 'phrases', 'how do you say', 'how to say', 'basic korean',
      'learn korean', 'korean words', 'say in korean',
      '표현', '한국어 표현', '기본 한국어', '한국어 공부', '말하는 법',
    ],
    answerEn: '• 안녕하세요 (annyeonghaseyo) — Hello\n'
        '• 감사합니다 (gamsahamnida) — Thank you\n'
        '• 죄송합니다 / 저기요 (joesonghamnida / jeogiyo) — Sorry / Excuse me (to call staff)\n'
        '• 이거 얼마예요? (igeo eolmayeyo?) — How much is this?\n'
        '• 한국어를 잘 못해요 (hangugeoreul jal motaeyo) — I don\'t speak Korean well\n'
        '• 영어 하실 수 있어요? (yeongeo hasil su isseoyo?) — Can you speak English?\n'
        'Practice more words in the Word Quiz on the Home tab!',
    answerKo: '• 안녕하세요 — 인사\n'
        '• 감사합니다 — 고마울 때\n'
        '• 죄송합니다 / 저기요 — 사과할 때 / 직원을 부를 때\n'
        '• 이거 얼마예요? — 가격을 물을 때\n'
        '• 한국어를 잘 못해요 — 한국어가 서툴 때\n'
        '• 영어 하실 수 있어요? — 영어가 되는지 물을 때\n'
        '홈 탭의 단어 퀴즈로 단어를 더 연습해 보세요!',
  ),

  // ------------------------------------------------------------ app help
  KbEntry(
    id: 'app_help',
    category: TopicCategory.appHelp,
    questionEn: 'How do I use this app?',
    questionKo: '이 앱은 어떻게 사용해요?',
    keywords: [
      'this app', 'how to use', 'quest', 'quests', 'calendar', 'word quiz', 'notice explained',
      'culture coach', 'saved journey', 'tabs',
      '이 앱', '앱 사용', '퀘스트', '캘린더', '일정', '단어 퀴즈', '공지 해설', '여정',
    ],
    answerEn: '• Home — ask me (Hodu) anything and play the Korean Word Quiz.\n'
        '• Quests — step-by-step tasks for your first weeks (SIM, bank card, ARC...).\n'
        '• Campus — Notice Explained turns Korean school notices into simple steps.\n'
        '• Culture — quiz yourself on everyday Korean etiquette.\n'
        '• Me — your calendar of deadlines and your saved journeys.',
    answerKo: '• 홈 — 호두에게 무엇이든 물어보고 한국어 단어 퀴즈를 풀어요.\n'
        '• 퀘스트 — 유심, 은행 카드, 외국인등록증 같은 첫 몇 주의 할 일을 단계별로 안내해요.\n'
        '• 캠퍼스 — 공지 해설이 어려운 학교 공지를 쉬운 단계로 바꿔 줘요.\n'
        '• 문화 — 한국 생활 예절 퀴즈를 풀어요.\n'
        '• 나 — 마감일 캘린더와 저장한 여정을 볼 수 있어요.',
  ),
];
