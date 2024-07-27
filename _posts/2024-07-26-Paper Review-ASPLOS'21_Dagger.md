---
title: "[Paper Review] ASPLOS'21 Dagger"
categories:
  - Paper
tags:
  - Network
  - FPGA
---
# Dagger: Efficient and Fast RPCs in Cloud Microservices withNear-Memory Reconfigurable NICs
<br>
>Due to copyright issues, I do not include `Figures` that are embedded in the paper :(
{: .prompt-warning }  

> This article is being edited
{: .prompt-danger }  
 
## Introduction
---

### Backgrounds

만약 여러분의 학교가 평균 1000명이 매분마다 접속한다치고 이를 위한 서버가 1억짜리라고 해봅시다  
그런데 10000명이 수강신청날 몰려든다라고 해볼게요. 이를 위한 서버가 10억짜리라고 해봅시다  
그럼 우리 학교는 무슨 서버를 살까요? 맞아요 1억짜리에요  

이를 위해 클라우드 서비스를 사용하는데요, 이런 수강신청날을 위해 빠르고 쉽게 도커같은 컨테이너들을 띄워 유연한 확장성을 갖춰보자는 것이 마이크로서비스 입니다  
그래서 이 마이크로서비스는 Fine-grained 하고 (번역 못하겠음) 가벼운 프로토콜을 가지고 있죠. 또 모듈성과 오류 격리성도 얻을 수 있고요.
<br><br>
### Problems

근데 뭐가 문제이길래? 저자는 이런 마이크로서비스와 같은 경우 보통 가벼운 계산만 포함하니 네트워킹이 전체 지연 시간을 높은 비율로 잡아먹는거 아니냐? 라고 말하고 있습니다.  
마이크로서비스는 보통 RPC(원격 프로시저 호출)을 통해 통신하는데, 이 프레임워크가 성능에 상당한 오버헤드를 초래한다고 하거든요.  

통신 오버헤드에 대한 부분은 `Figure 3` 에서 저자의 연구 결과를 보여주고 있습니다. 3.1장을 읽어보면 자세히 알아볼 수 있습니다. 이는 네트워킹 스택에서의 과한 대기 때문이라고 하는데요. RPC 계층에서의 공격적 대기는 메모리 압력을 증가시키고 다른 작업과 메모리 간섭을 초래해 지연 시간을 더 길게 만든다고 합니다.  

그걸 개선하고자 많은 연구가 있었지만, 결국 CPU와 NIC 사이에 인터페이스에서 제한이 생긴다라는 것이죠. NIC은 프로세서에 PCIe로 연결된 주변장치일 뿐이고 PCIe에 의해 버스 트랜잭션이나 메모리 동기화 등에 제한이 생깁니다.

자세한 부분은 아래 Summary에 적어놓았습니다.
<br><br>
### Solutions

그래서 저자는 FPGA를 이용해 Reconfigurable한 RPC 스택을 만들었고, 이를 Dagger라고 칭했습니다.  
Dagger is based on three key design principles:  
1) NIC이 전체 RPC 스택을 하드웨어로 구현하고, 소프트웨어는 RPC API 제공만 담당하고  
2) Dagger가 프로세서와 통신하기 위해 메모리 인터커넥트를 활용하며  
3) FPGA 기반으로 완전히 프로그래밍이 가능하도록  

이렇게 함으로 Dagger를 통해 CPU 자원을 효율적으로 사용하고 요청 지연 시간을 크게 줄여보자는 것이죠!  

<br><br>
## Summary
---

### Problems

위에서와 `Figure 3`에서 이야기했듯 RPC 처리와 전송 계층에서 통신 오버헤드가 상당 부분을 차지합니다.  
그리고 평범한 SNS 서비스(인스타그램, 트위터..)를 예시로 들면 사용자 게시물의 이미지와 비디오 처리, 계정을 관리하고, 텍스트를 추가하고, 다른 사용자를 태그하는 등 여러가지 다른 크기의 패킷들이 오고 갈 수 있는데요. `Figure 4`에서는 패킷 당 오버헤드가 높아 작은 패킷을 전송할 때 성능이 저하된다는 것을 보여주고 있습니다. 동일한 어플리케이션에서 매우 다른 RPC 크기를 가지고 있으니 한 가지 방법으로 모든 걸 해결하는 건 마이크로서비스에 적합하지 않다는 것이죠. 그래서 FPGA로 네트워킹 스택을 각각의 요구와 특성에 맞춰줘야 한다는 겁니다.  

`Figure 5` 에서는 Multi-Tenancy가 초래하는 마이크로서비스 로직과 네트워크 처리 간의 자원 경합을 정량화해서 보여주고 있습니다. 예상대로 CPU 자원이 경합될 때 레이턴시가 증가하는 것을 보여주고 있죠. 그에 따라 저자는 네트워킹 스택을 프로세서에서 오프로드 해야한다고 주장합니다. 하지만 네트워크 처리를 위해 전용 코어를 할당하는 건 반대합니다. 부하에 따라 결국 LLC와 메인 메모리 서브시스템에 간섭을 줄 것이라 합니다.  

따라서 저자는 RPC 처리를 CPU 관련 오버헤드와 간섭을 피하기 위해 오프로드하고, 마이크로서비스의 작은 요청과 응답을 잘 처리하도록 최적화해야하며, 통신 프레임워크가 자주 변화하는 특성에 맞추기 위해 프로그래밍이 가능해야 한다고 합니다.

<br>
### Dagger Architecture

Dagger는 앞서 Problems에서 이야기 한 내용들을 해결할 가속기 입니다.  
그에 따른 아키텍처가 `Figure 6`에 나와있습니다.  
1) 전체 하드웨어를 오프로드 하고 "Full Hardware Offload"  
2) 타이트하게 서로 결합하며 "Tight Coupling"  
3) 재구성이 가능하도록! "Reconfigurability"  

1) Full Hardware Offload
- 들어오는 RPC 요청과 응답을 버퍼를 이용해 배치하고 나머지 처리는 Dagger에 포함된 NIC 모듈이 처리합니다.

2) Tight Coupling
- Dagger는 Host와 NUMA 메모리 인터커넥트(이하 NUMA)를 사용하여 RPC 전송을 최적화합니다. NUMA는 CCI-P 프로토콜 스택으로 캡슐화 되어있다고 하네요.

3) Reconfigurability
- Dagger의 설계는 Intel OPAE HDK를 기반으로 Blue Bitstream과 Green Bitstream 두 가지 프로그래머블한 로직 영역을 정의했다고 합니다.
- Blue Bitstream
	- CCI-P 인터페이스 IP, 이더넷 PHY, 클럭 생성기 등등
- Green Bitstream
	- 사용자 로직 구현, Dagger NIC

더 자세한 부분은 본문 4장을 확인해보세요!!
<br><br>

### API & Threading Model

API는 클라우드 애플리케이션의 표준 클라이언트-서버 아키텍쳐를 따른다고 합니다. 그리고 자체 인터페이스 정의 언어(이하 IDL)와 코드 생성기를 가지고 있다고 합니다. Google Protobuf IDL을 채택했고, `Listing 1`은 인터페이스 정의 예시를 보여주고 있습니다.  

코드 생성기는 대상 IDL 파일을 파싱하고 하드웨어에 쓰기/읽기 중인 낮은 수준의 RPC 구조를 높은 수준의 서비스 API 함수 호출로 랩핑하는 클라이언트 및 서버 stubs를 생성한다고 합니다. 이 API에 두가지 중요한 클래스가 있는데요 

<br><br>

<br><br>
## Review
---


<br><br>
## Strength & Weakness
---


<br><br>

Thanks!!