# **ConnectX**

**ConnectX** is a mobile application that enables offline chat and media sharing without needing an internet connection or a SIM card. Built using **Flutter**, ConnectX facilitates peer-to-peer (**P2P**) communication over the **Wi-Fi Direct API**, making it ideal for secure, local communication in any environment.

---

## **Features**

### **Offline Messaging**
- Send and receive messages without internet access.
- Uses **Wi-Fi Direct** to connect devices on a local network.

### **Media Sharing**
- Share images, videos, documents, and other media files with nearby devices.

### **Peer-to-Peer Communication**
- Direct device-to-device communication using the **Wi-Fi Direct API**.
- No central server or internet connection required.

### **No SIM Required**
- Works independently of cellular networks and SIM cards.

### **Seamless & Secure File Transfers**
- Optimized and secure protocol for file sending and receiving.

## **Use Cases**

- Offline communication in remote areas, during travel, or in disaster recovery scenarios.
- Instant file transfers without the need for internet or cloud services.
- Secure local networking, free from exposure to online threats.

---

## **Technical Overview**

- **Framework**: **Flutter** (cross-platform mobile development)
- **Networking**: **Wi-Fi Direct API** (peer discovery and connection handling)
- **Storage**: **Shared Preferences** for local storage of user data
- **Offline Architecture**: Fully offline design without reliance on online services

---

## **Technology Stack**

| **Component**       | **Technology**                |
|---------------------|-------------------------------|
| **Frontend**        | **Flutter**                   |
| **Networking**      | **Wi-Fi Direct API**          |
| **Local Storage**   | **Shared Preferences**        |
| **Communication Layer** | **Socket Programming**        |

---

## **Design Patterns**

ConnectX makes use of the **Singleton Pattern** where appropriate — particularly in components that manage shared services like peer discovery, socket communication, or application-wide configuration. The Singleton Pattern ensures that a class has only one instance throughout the app's lifecycle and provides a global point of access to it. This is especially useful for maintaining consistent connection state.

## **License**

This project is licensed under the [**MIT License**](./LICENSE).

---

## **Contributing**

Contributions are welcome. Feel free to fork the repository and submit a pull request with improvements or bug fixes.

---

## **Acknowledgements**

Thanks to the **Flutter community** and **open source developers** for providing the tools and libraries that made this project possible.

> **Built by the ConnectX Team.**
