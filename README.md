# 🌐 Web Uptime Monitor  

**Author:** Khalid Hashim | Cloud Engineer  
**Tech:** AWS ☁️, CloudWatch 📊, S3 🗃️, SNS ✉️, Node.js 💻, Puppeteer 🤖  

---

## 📝 Project Overview  

This project monitors website uptime using **AWS Synthetics Canary**.  
It automatically checks your site every 5 minutes, logs metrics to CloudWatch, and sends alerts via SNS if the site is down.  

It demonstrates skills in **IaC, cloud monitoring, and automation**.  

---

## 🏗️ Architecture  

**Synthetics Canary → CloudWatch Metrics → SNS Alerts**  

**Components:**  
- **Canary:** Runs Puppeteer to check website status ✅  
- **S3 Buckets:** Store code & execution artifacts 🗃️  
- **IAM Roles & Policies:** Give secure permissions 🔐  
- **CloudWatch Alarm:** Alerts if uptime drops 📊  
- **SNS Notifications:** Email alerts ✉️  

---

## ⚡ Features  

- Website uptime checks every 5 mins (change it to 1 day) for cost ⏱️  
- Metrics & logs stored in CloudWatch 📊  
- Automatic deployment of canary code to S3 🗂️  
- SNS email notifications on failures ✉️  

---

👀 Observability

- SuccessPercent metric in CloudWatch 📊
- Alarm triggers if uptime < 90% 🚨
- Logs, screenshots, and HAR files available in AWS Console 🖥️

💡 Skills Showcased

- Terraform IaC 🛠️
- Serverless monitoring with Puppeteer 🤖
- CloudWatch & SNS alerting 📊✉️
- Cloud security with IAM 🔐
- Automation & DevOps practices ⚡

🌟 Demo

- Website uptime monitored: https://khalidhashim.com
- Canary metrics visible in AWS CloudWatch Synthetics Console ☁️
