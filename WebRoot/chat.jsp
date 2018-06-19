<%@ page language="java" contentType="text/html; charset=UTF-8"
	pageEncoding="UTF-8"%>
<%
	String name = request.getParameter("username");
	session.setAttribute("user", name);
%>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Chat</title>
<style type="text/css">
input#chat {
	width: 400px;
}

#image {
	width: 400px;
}

#console-container {
	width: 80%;
}

#console {
	border: 1px solid #CCCCCC;
	border-right-color: #999999;
	border-bottom-color: #999999;
	height: 80%;
	overflow-y: scroll;
	padding: auto;
	width: 100%;
}

#console p {
	padding: 0;
	margin: 0;
}
</style>
<script type="text/javascript"
	src="https://cdn.bootcss.com/jquery/3.3.1/jquery.min.js"></script>
<script type="text/javascript"
	src="https://cdn.bootcss.com/jsencrypt/3.0.0-beta.1/jsencrypt.min.js"></script>
<script type="text/javascript"
	src="https://cdn.bootcss.com/crypto-js/3.1.9/core.min.js"></script>
<script type="text/javascript"
	src="https://cdn.bootcss.com/crypto-js/3.1.9/crypto-js.min.js"></script>
<script type="text/javascript" src="md5.js"></script>
<script type="application/javascript">
	"use strict";

	var Chat = {};
	var myname = "<%=name%>";
	var crypt = new JSEncrypt({
		default_key_size : 1024
	});
	var targetcrypt = new JSEncrypt();
	var myPrivateKey = crypt.getPrivateKey();
	var myPublicKey = crypt.getPublicKey();
	crypt.setPrivateKey(myPrivateKey);
	var aesdic = new Dictionary();
	var temp = new Dictionary();
	var user = new Dictionary();
	Chat.socket = null;

	Chat.connect = (function(host) {
		if ('WebSocket' in window) {
			Chat.socket = new WebSocket(host);
		} else if ('MozWebSocket' in window) {
			Chat.socket = new MozWebSocket(host);
		} else {
			Console.log('Error: WebSocket is not supported by this browser.');
			return;
		}

		Chat.socket.onopen = function() {
			Console.log('***Connection Open.');
			Chat.sendInfo("0000000000000000" + myname.MD5() + "log" + "0" + myname);
			Chat.sendInfo("0000000000000000" + myname.MD5() + "ruk" + "0" + myPublicKey);
			alert("My Private Key is\n" + myPrivateKey);
			jsAddItemToSelect(document.getElementById("userlist"), 'Please select a user', '0');
			document.getElementById('chat').onkeydown = function(event) {
				if (event.keyCode == 13) {
					Chat.sendMessage();
				}
			};
		};

		Chat.socket.onclose = function() {
			document.getElementById('chat').onkeydown = null;
			Console.log('***Connection Close.');
		};

		Chat.socket.onmessage = function(message) {
			switch (message.data.substring(32, 35)) {
			case "usi": {
				if (message.data.substring(36, 52) != myname.MD5()) {
					user.set(message.data.substring(36, 52), message.data.substring(52));
					jsAddItemToSelect(document.getElementById("userlist"), message.data.substring(52), message.data.substring(36, 52));
				}
				//Console.log("*join in:" + message.data.substring(52));
				break;
			}
			case "uso": {
				user.remove(message.data.substring(36, 52));
				jsRemoveItemFromSelect(document.getElementById("userlist"), message.data.substring(36, 52));
				//Console.log("*out:" + message.data.substring(52));
				break;
			}
			case "rep": {
				targetcrypt.setPublicKey(message.data.substring(36));
				alert("Get Public key : \n" + message.data.substring(36));
				break;
			}
			case "txt": {
				//crypt.decrypt(message.data.substring(36));
				Console.log(user.get(message.data.substring(16, 32)) + ":" + crypt.decrypt(message.data.substring(36)));
				break;
			}
			case "aes": {
				//Console.log(crypt.decrypt(message.data.substring(36)));
				aesdic.remove(message.data.substring(16, 32));
				aesdic.set(message.data.substring(16, 32), crypt.decrypt(message.data.substring(36)));
				break;
			}
			case "pic": {
				var aesphoto = getDAes(message.data.substring(36), aesdic.get(message.data.substring(16, 32)).substring(0, 32), aesdic.get(message.data.substring(16, 32)).substring(32));
				//Console.log(aesphoto);
				Chat.photo(aesphoto, message.data.substring(16, 32));
				break;
			}
			}

		//Console.log(message.data);
		};
	});

	Chat.initialize = function() {
		if (window.location.protocol == 'http:') {
			Chat.connect('ws://' + '127.0.0.1:8080' + '/chat/websocket/chat');
		} else {
			Chat.connect('wss://' + '127.0.0.1:8080' + '/chat/websocket/chat');
		}
	};

	Chat.sendMessage = (function() {
		var message = document.getElementById('chat').value;
		var touser = document.getElementById('userlist').value + "";
		if (touser.length != 16) {
			alert("please select a user!");
		} else {
			if (message != '') {
				Chat.socket.send(touser + myname.MD5() + "txt" + "1" + targetcrypt.encrypt(message));
				Console.log("Me:" + message);
				document.getElementById('chat').value = '';
			}
		}
	});

	Chat.sendInfo = (function(info) {
		if (info != '') {
			Chat.socket.send(info);
		}
	});

	Chat.sendAes = (function(aes) {
		var touser = document.getElementById('userlist').value + "";
		if (touser.length != 16) {
			alert("please select a user!");
		} else {
			Chat.socket.send(touser + myname.MD5() + "aes" + "1" + targetcrypt.encrypt(aes));
		}
	});

	Chat.sendPhoto = (function(photo) {
		var touser = document.getElementById('userlist').value + "";
		if (touser.length != 16) {
			alert("please select a user!");
		} else {

			var aesphoto;
			var key = randomkey();
			var iv = randomiv();
			const packsize = 5000;
			Chat.sendAes(key + iv);
			var total = Math.ceil(photo.length / packsize);
			for (var local = 0; local < total; local++) {
				if (total - local == 1) {
					//Console.log(pad(local, 4) + pad(total, 4) + photo.substring(local * packsize));
					aesphoto = getAES(pad(local, 4) + pad(total, 4) + photo.substring(local * packsize), key, iv);
				} else {
					//Console.log(pad(local, 4) + pad(total, 4) + photo.substring(local * packsize, (local + 1) * packsize));
					aesphoto = getAES(pad(local, 4) + pad(total, 4) + photo.substring(local * packsize, (local + 1) * packsize), key, iv);
				}
				Chat.socket.send(touser + myname.MD5() + "pic" + "0" + aesphoto);
			}
			Console.log("I Send a Photo:");
			Console.photo(photo);
		}
	});

	Chat.getKey = (function() {
		var touser = document.getElementById('userlist').value + "";
		if (touser.length != 16) {
			getAES
			alert("please select a user!");
		} else {
			Chat.socket.send("0000000000000000" + myname.MD5() + "ask" + "0" + touser);
		}
	});

	Chat.photo = (function(aesphoto, fromuser) {
		var local = Number(aesphoto.substring(0, 4));
		var total = Number(aesphoto.substring(4, 8));
		if (temp.has(fromuser)) {
			temp.set(fromuser, temp.get(fromuser) + aesphoto.substring(8));
		} else {
			temp.set(fromuser, aesphoto.substring(8))
		}
		if (local == (total - 1)) {
			Console.log(user.get(fromuser) + " Send a Photo:");
			Console.photo(temp.get(fromuser));
			temp.remove(fromuser);
		}
	});

	var Console = {};

	Console.log = (function(message) {
		var console = document.getElementById('console');
		var p = document.createElement('p');
		p.style.wordWrap = 'break-word';
		p.innerHTML = message;
		console.appendChild(p);
		while (console.childNodes.length > 25) {
			console.removeChild(console.firstChild);
		}
		console.scrollTop = console.scrollHeight;
	});

	Console.photo = (function(photo) {
		var console = document.getElementById('console');
		var img = document.createElement('img');
		img.src = photo;
		console.appendChild(img);
		//console.scrollTop = console.scrollHeight;
	});

	Chat.initialize();


	document.addEventListener("DOMContentLoaded", function() {
		// Remove elements with "noscript" class - <noscript> is not allowed in XHTML
		var noscripts = document.getElementsByClassName("noscript");
		for (var i = 0; i < noscripts.length; i++) {
			noscripts[i].parentNode.removeChild(noscripts[i]);
		}
	}, false);

	function jsSelectIsExitItem(objSelect, objItemValue) {
		var isExit = false;
		for (var i = 0; i < objSelect.options.length; i++) {
			if (objSelect.options[i].value == objItemValue) {
				isExit = true;
				break;
			}
		}
		return isExit;
	}

	function jsAddItemToSelect(objSelect, objItemText, objItemValue) {
		if (jsSelectIsExitItem(objSelect, objItemValue)) {
		} else {
			var varItem = new Option(objItemText, objItemValue);
			objSelect.options.add(varItem);
		}
	}

	function jsRemoveItemFromSelect(objSelect, objItemValue) {
		if (jsSelectIsExitItem(objSelect, objItemValue)) {
			for (var i = 0; i < objSelect.options.length; i++) {
				if (objSelect.options[i].value == objItemValue) {
					objSelect.options.remove(i);
					break;
				}
			}
		} else {
		}
	}

	function btnChange(values) {
		if (values == "0") {
			alert("please select a user!");
		} else {
			Chat.getKey();
		}
	}

	function photo() {
		var reader = new FileReader();
		var AllowImgFileSize = 2097152;
		var file = $("#image")[0].files[0];
		var imgUrlBase64;
		if (file) {
			imgUrlBase64 = reader.readAsDataURL(file);
			reader.onload = function(e) {
				//var ImgFileSize = reader.result.substring(reader.result.indexOf(",") + 1).length;//截取base64码部分（可选可不选，需要与后台沟通）
				if (AllowImgFileSize != 0 && AllowImgFileSize < reader.result.length) {
					alert('too big');
					return;
				} else {
					Chat.sendPhoto(reader.result)
				}
			}
		}
	}

	function getAesString(data, key, iv) {
		var key = CryptoJS.enc.Utf8.parse(key);
		var iv = CryptoJS.enc.Utf8.parse(iv);
		var encrypted = CryptoJS.AES.encrypt(data, key,
			{
				iv : iv,
				mode : CryptoJS.mode.CBC,
				padding : CryptoJS.pad.Pkcs7
			});
		return encrypted.toString();
	}
	function getDAesString(encrypted, key, iv) {
		var key = CryptoJS.enc.Utf8.parse(key);
		var iv = CryptoJS.enc.Utf8.parse(iv);
		var decrypted = CryptoJS.AES.decrypt(encrypted, key,
			{
				iv : iv,
				mode : CryptoJS.mode.CBC,
				padding : CryptoJS.pad.Pkcs7
			});
		return decrypted.toString(CryptoJS.enc.Utf8).toString();
	}

	function getAES(data, key, iv) {
		var encrypted = getAesString(data, key, iv);
		var encrypted1 = CryptoJS.enc.Utf8.parse(encrypted);
		return encrypted;
	}

	function getDAes(data, key, iv) {
		var decryptedStr = getDAesString(data, key, iv);
		return decryptedStr;
	}

	function Dictionary() {
		var items = {};
		this.set = function(key, value) {
			items[key] = value;
		};
		this.remove = function(key) {
			if (this.has(key)) {
				delete items[key];
				return true;
			}
			return false;
		};
		this.has = function(key) {
			return items.hasOwnProperty(key);
		};
		this.get = function(key) {
			return this.has(key) ? items[key] : undefined;
		};
		this.clear = function() {
			items = {};
		};
		this.size = function() {
			return Object.keys(items).length;
		};
		this.keys = function() {
			return Object.keys(items);
		};
		this.values = function() {
			var values = [];
			for (var k in items) {
				if (this.has(k)) {
					values.push(items[k]);
				}
			}
			return values;
		};
		this.each = function(fn) {
			for (var k in items) {
				if (this.has(k)) {
					fn(k, items[k]);
				}
			}
		};
		this.getItems = function() {
			return items;
		}
	}

	function randomkey(len) {
		len = len || 32;
		var $chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
		var maxPos = $chars.length;
		var pwd = '';
		for (var i = 0; i < len; i++) {
			pwd += $chars.charAt(Math.floor(Math.random() * maxPos));
		}
		return pwd;
	}

	function randomiv(len) {
		len = len || 16;
		var $chars = '0123456789';
		var maxPos = $chars.length;
		var pwd = '';
		for (var i = 0; i < len; i++) {
			pwd += $chars.charAt(Math.floor(Math.random() * maxPos));
		}
		return pwd;
	}

	function pad(num, n) {
		var len = num.toString().length;
		while (len < n) {
			num = "0" + num;
			len++;
		}
		return num;
	}
</script>
</head>
<body>
	<div class="noscript">
		<h2 style="color: #ff0000">Seems your browser doesn't support
			Javascript! Websockets rely on Javascript being enabled. Please
			enable Javascript and reload this page!</h2>
	</div>
	<div align="center">
		<div id="console-container">
			<div id="console" align="left" /></div>
		</div>
		<p>
			<input type="text" placeholder="type and press enter to chat"
				id="chat" />
			<button id="btn1" onclick="Chat.sendMessage()">send txt</button>
		</p>
		<p>
			<input type="file" id="image">
			<button id="btn2" onclick="photo()">send pic</button>
		</p>
		
		<p>
			<select id='userlist' onchange='btnChange(this[selectedIndex].value);'></select>
			<span style="color: red;">*</span>⭐choose a target user 🏹
		</p>
	</div>
</html>