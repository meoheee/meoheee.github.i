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

더 자세한 부분은 본문 4.1장을 확인해보세요!!
<br><br>

### API & Threading Model

API는 클라우드 애플리케이션의 표준 클라이언트-서버 아키텍쳐를 따른다고 합니다. 그리고 자체 인터페이스 정의 언어(이하 IDL)와 코드 생성기를 가지고 있다고 합니다. Google Protobuf IDL을 채택했고, `Listing 1`은 인터페이스 정의 예시를 보여주고 있습니다. 코드 생성기는 대상 IDL 파일을 파싱하고 하드웨어에 쓰기/읽기 중인 낮은 수준의 RPC 구조를 높은 수준의 서비스 API 함수 호출로 랩핑하는 클라이언트 및 서버 stubs를 생성한다고 합니다.  

Threading Model은 `figure 7`에 나와있는 것 처럼 RX/TX 링에 1대1로 매핑되도록 합니다. 각 flow 수는 CPU 코어 수에 따라 결정된다고 하네요. 그리고 스레드 간의 통신 오버헤드를 피하기 위해 dispatch 스레드에서 RPC 핸들러를 실행합니다.[^footnote] 그리고 *RpcClient*의 연결은 동일한 RX/TX 링을 공유하므로 Dagger는 Shared Receive Queue(이하 SRQ) 모델을 구현합니다.  다시 말하면 CPU 코어 수에 따라 Dagger가 확장된다라는 말인 것 같네요.

Dagger는 Connection들을 모두 하드웨어에서 관리하니 `Figure 6`에 보이듯 Connection Manager(이하 CM) 모듈들이 포함되는데, Connection Table Interface가 연결 ID를 튜플에 매핑합니다. 아래는 연결 ID입니다.
- `src_flow` : 클라이언트에서 요청을 수신하는 Flow ID 지정  
- `dest_addr`, `load_balancer` : 호스트의 목적지 주소와 선호되는 load balancing scheme 정의  
CM은 특정 메모리 조직을 가진 간단한 direct-mapped 캐시로 설계됐습니다. 캐시 접근과 관련한 내용은 본문을 확인해주세요!!  
<br><br>

### NUMA Interconnects

저자는 앞서 언급한대로 NIC과 호스트의 연결에 있어 PCIe는 비효율적이다 라고 강력하게 주장하고 있습니다. 주로 호스트 메모리에서 네트워크 패킷을 가져올 때가 문제라는데, 단순 예시로 보통 NIC은 DMA 전송을 사용하는데, 버퍼에서 Packet Descriptor와 Payload를 읽기 위해 MMIO Doorbell transaction에 의해 시작된 것입니다.[^fn-nth-2] 음...Doorbell이 뭔지는 저도 잘 모르겠네요..!?ㅠㅠ 저 각주 논문도 빠른 시일 내에 읽어보도록 할게요!  

아무튼 요런 단순한 Doorbell Scheme은 앞서 문제라 했던 작은 요청이 대상일 경우 비효율적이라는 겁니다. MMIO 트랜잭션은 non-casheable writes로 구현돼서 느리고 비싸다고 하네요. 모든 MMIO 요청이 프로세서를 거치기 때문입니다.  

아무튼 PCIe 프로토콜은 근본적으로 생산자-소비자 데이터 모델이 맞춰 설계되었으니 대규모 데이터 전송에서는 잘 작동하지만 RPC Request에서는 적절하지 않아요! 위에서 그 이유는 설명했듯 크기가 작거든요!  

그런데 NUMA를 사용하게 되면 프로세서의 메모리 서브시스템에 I/O를 통합할 수 있어서 프로세서에게 데이터 업데이트 한다! 라고 말하지 않아도 된다고 합니다. 그럼 프로세서가 할 일이 NIC과 공유하는 버퍼에 RPC 요청/응답을 쓰는 것 밖에 없으니 효율성이 향상되죠.  

결론은 PCIe 말고 NUMA 쓰자! 입니다!
<br><br>
### Implementation

#### NIC Interface
`Figure 8`은 NIC I/O 인터페이스를 보여줍니다. 위에서 보신듯이 Dagger는 NIC flow마다 RX/TX 버퍼를 제공하고 있고 있습니다. 이건 당연히 오고가는 RPC를 위한 것이구요. RX의 경우 RPC 데이터를 가져오기 위해 PCIe DMA를 기반으로 한다고 합니다. TX는 `Figure 9`의 그림을 통해 나타냈으며, 들어오는 RPC를 FIFO 버퍼로 처리한다고 합니다. 그리고 로드밸런서와 flow 스케줄러가 포함되어 있습니다.

#### RPC Pipeline

CPU-NIC의 인터페이스 ->RPC 모듈 -> Transport Layer 입니다. `Figure 6`에도 명시했네요.

#### Dagger Implementation

- CPU : Intel Broadwell
- FPGA : Arria 10 GX1150
- Host CPU : Intel Xeon E5-2600v4
- Hardware (Dagger NIC) -> SystemVerilog, OPAE HDK lib.
- Software : C++11, GCC로 Compile
- Dagger IDL : Python 3.7

<br><br>
#### Evaluation 파트는 생략입니다!

그냥 다른 관련 연구들과의 비교일 뿐입니다. RPC 처리에 대해 더 빠르고 효율적이며 PCIe를 썼을 때보다 더 빠르다는 내용입니다. 딱 하나 봐야 할 내용이 있다면, 스레드 확장 시 7개까지 선형으로 좋아지지만 8개부터는 아니다라는 겁니다.
<br>
<br>
## Review
---

조오금 저에게는 어려운 논문이었어요! 아무튼 저자는 기존 HTTP의 데이터 처리 방식과 같은 마이크로서비스에서 RPC 요청들이 들어올 때 크기가 작은 요청들에 대해서는 굉장히 비효율적이다! 라고 문제제기를 했죠. 그 이유로 PCIe의 비효율적인 문제와 메모리 접근을 위해 프로세서를 거치는 부분에서 발생하는 오버헤드가 있다고 했습니다. 이를 위해 결론적으로 NIC을 Dagger NIC이라는 새로운 모듈을 개발하여 연산 위치를 하드웨어로 오프로드해보고, PCIe를 탈피하고 메모리-인터커넥트, UPI를 사용하며 비효율적인 RPC 처리를 개선했다고 합니다.  

NIC을 통째로 재구현했다는 점에 저는 좀 놀랐어요..! 하드웨어 개발자분들이라면 아실 듯 하지만 처음부터 끝까지 모듈을 모두 설계한다!!!라는건 진짜진짜 미친짓 같아 보이거든요. 저자의 엄청난 노력과 고생이 논문을 읽으며 계속 보였습니다.  

또한 논문도 굉장히 짜임새있게 잘 쓴 게 보입니다. 특히 단순히 언급하고 넘어갈만한 RPC 요청에 대한 오버헤드 부분을 소단원까지 나눠가며 세밀한 그래프와 함께 두툼하게 문제 제기를 했죠. 그러다보니 저도 논문 리뷰를 하며 Problems 파트를 두 번이나 쓰게 되었네요..!   

다만 아쉬운 건 `Figure 6`의 그림이 논문에서 매우 큰 비중을 차지하고 있음에도 각각의 모듈별 설계에 대한 설명이 이루어졌었으면 좋겠었지만, 목록화가 되어있지 않고 4장에 전반적으로 흩어져 설명이 되어있어 그림과 설명을 왔다갔다하며 읽기 힘든 점이었습니다.   

하지만 그럼에도 RPC 연산에서 만큼은 PCIe 말고 메모리-인터커넥트를 사용해야한다! 라고 다시 알게 해준 아주 중요한 부분을 찝어 논문에서 설명하고 있습니다.  
<br><br>
## Strength & Weakness
---

### Strength

1) PCIe보다 NUMA가 더 효율적임을 강하게 주장을 잘 드러냈습니다.


### Weakness

1) 어느 논문이나 단점이 있듯, 작은 RPC 요청에 초점을 맞추다보니 반대로 큰 RPC 요청에 대해서는 캐시 라인 크기의 제한으로 인해 소프트웨어 상에서 재조립을 해줘야한다는 겁니다.  



## High Influenced Related Works

1) Mohammad Alian and Nam Sung Kim. 2019. NetDIMM: Low-Latency NearMemory Network Interface Architecture. Int’l Symp. on Microarchitecture (MICRO) (2019)  
2) Stanko Novakovic, Alexandros Daglis, Edouard Bugnion, Babak Falsafi, and Boris Grot. 2014. Scale-out NUMA. Int’l Conf. on Architectural Support for Programming Languages and Operating Systems (ASPLOS) (2014)  
3) Mark Sutherland, Siddharth Gupta, Babak Falsafi, Virendra Marathe, Dionisios Pnevmatikatos, and Alexandros Daglis. 2020. The NeBuLa RPC-Optimized Architecture. Int’l Symp. on Computer Architecture (ISCA) (2020)  
4) Mina Tahmasbi Arashloo, Alexey Lavrov, Manya Ghobadi, Jennifer Rexford, David Walker, and David Wentzlaff. 2020. Enabling Programmable Transport Protocols in High-Speed NICs. USENIX Symp. on Networked Systems Design and Implementation (NSDI) (2020)  
5) Haggai Eran, Lior Zeno, Maroun Tork, Gabi Malka, and Mark Silberstein. 2019. NICA: An Infrastructure for Inline Acceleration of Network Applications. USENIX Annual Technical Conf. (ATC) (July 2019)
6) Daniel Firestone, Andrew Putnam, Sambhrama Mundkur, Derek Chiou, Alireza Dabagh, Mike Andrewartha, Hari Angepat, Vivek Bhanu, Adrian Caulfield, Eric Chung, Harish Kumar Chandrappa, Somesh Chaturmohta, Matt Humphrey, Jack Lavier, Norman Lam, Fengfen Liu, Kalin Ovtcharov, Jitu Padhye, Gautham Popuri, Shachar Raindel, Tejas Sapre, Mark Shaw, Gabriel Silva, Madhan Sivakumar, Nisheeth Srivastava, Anshuman Verma, Qasim Zuhair, Deepak Bansal, Doug Burger, Kushagra Vaid, David A. Maltz, and Albert Greenberg. 2018. Azure Accelerated Networking: SmartNICs in the Public Cloud. In Proceedings of the 15th USENIX Conference on Networked Systems Design and Implementation (Renton, WA, USA) (NSDI’18). USENIX Association, USA, 51–64
7) Phitchaya Mangpo Phothilimthana, Ming Liu, Antoine Kaufmann, Simon Peter, Rastislav Bodik, and Thomas Anderson. 2018. Floem: A Programming System for NIC-Accelerated Network Applications. Symposium on Operating Systems Design and Implementation (OSDI) (2018)
<br><br>

Thanks!!
<br><br>


[^footnote]: Aleksandar Dragojević, Dushyanth Narayanan, Miguel Castro, and Orion Hodson. 2014. FaRM: Fast Remote Memory. USENIX Symp. on Networked Systems Design and Implementation (NSDI) (2014).  
[^fn-nth-2]: Anuj Kalia, Michael Kaminsky, and David G. Andersen. 2016. Design Guidelines for High Performance RDMA Systems. USENIX Annual Technical Conf. (ATC) (2016).