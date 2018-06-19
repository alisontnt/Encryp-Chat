/*
 *  Licensed to the Apache Software Foundation (ASF) under one or more
 *  contributor license agreements.  See the NOTICE file distributed with
 *  this work for additional information regarding copyright ownership.
 *  The ASF licenses this file to You under the Apache License, Version 2.0
 *  (the "License"); you may not use this file except in compliance with
 *  the License.  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */
package chat;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CopyOnWriteArraySet;
import java.util.concurrent.atomic.AtomicInteger;

import javax.websocket.OnClose;
import javax.websocket.OnError;
import javax.websocket.OnMessage;
import javax.websocket.OnOpen;
import javax.websocket.Session;
import javax.websocket.server.ServerEndpoint;


import chat.HTMLFilter;

@ServerEndpoint(value = "/websocket/chat")
public class ChatAnnotation {

    

    //private static final String GUEST_PREFIX = "Guest";
    //private static final AtomicInteger connectionIds = new AtomicInteger(0);
    private static final Set<ChatAnnotation> connections =
            new CopyOnWriteArraySet<>();

    
    private String nickname;
    private String nickname_md5;
    private Session session;
    
    private static final Map<String,String> m1 = new HashMap<String,String>();
    private static final Map<String,String> m2 = new HashMap<String,String>();

    public ChatAnnotation() {
        
    }


    @OnOpen
    public void start(Session session) {
        this.session = session;
        connections.add(this);
    }


    @OnClose
    public void end() {
        connections.remove(this);
        userout(nickname);
    }


    @OnMessage
    public void incoming(String message) {
        // Never trust the client
        /*String filteredMessage = String.format("%s: %s",
                nickname, HTMLFilter.filter(message.toString()));*/
    	String to_user = message.substring(0, 16);
    	if (to_user.equals("0000000000000000")){
    		String from_user = message.substring(16, 32);
    		String contral = message.substring(32, 35);
    		String cryp_opt = message.substring(35, 36);
    		String data = message.substring(36);
    		switch (contral){
    			case "log":{
    				m1.put(from_user, data);
    				nickname = data;
    				nickname_md5 = from_user;
    				userin();
    				break;
    			}
    			case "ruk":{
    				m2.put(from_user, data);
    				break;	
    			}case "ask":{
    				sendto(from_user,"rep"+"0"+m2.get(data));
    			}
    		}
    		broadcast(message);
    	}
    	else{
    		transto(to_user,message);
    		//broadcast_test(message);
    	}
        
    }




    @OnError
    public void onError(Throwable t) throws Throwable {
        
    }
    
    private static void broadcast_test(String msg) {
        for (ChatAnnotation client : connections) {
            try {
                synchronized (client) {
                    client.session.getBasicRemote().sendText(msg);
                }
            } catch (IOException e) {
                
                connections.remove(client);
                try {
                    client.session.close();
                } catch (IOException e1) {
                    // Ignore
                }
                userout(client.nickname_md5);
            }
        }
    }


    private static void broadcast(String msg) {
        for (ChatAnnotation client : connections) {
            try {
                synchronized (client) {
                    client.session.getBasicRemote().sendText("0000000000000000"+client.nickname_md5+msg);
                }
            } catch (IOException e) {
                
                connections.remove(client);
                try {
                    client.session.close();
                } catch (IOException e1) {
                    // Ignore
                }
                userout(client.nickname_md5);
            }
        }
    }
    
    private static void transto(String touser,String msg) {
        for (ChatAnnotation client : connections) {
            try {
                synchronized (client) {
                	if (client.nickname_md5.equals(touser)){
                		client.session.getBasicRemote().sendText(msg);
                		break;
                	}
                }
            } catch (IOException e) {
                
                connections.remove(client);
                try {
                    client.session.close();
                    
                } catch (IOException e1) {
                    // Ignore
                }
                userout(client.nickname_md5);
            }
        }
    }
    
    private static void sendto(String touser,String msg) {
        for (ChatAnnotation client : connections) {
            try {
                synchronized (client) {
                	if (client.nickname_md5.equals(touser)){
                		client.session.getBasicRemote().sendText(touser + client.nickname_md5 + msg);
                		break;
                	}
                }
            } catch (IOException e) {
                
                connections.remove(client);
                try {
                    client.session.close();
                } catch (IOException e1) {
                    // Ignore
                }
                userout(client.nickname_md5);
            }
        }
    }
    
    private static void userin() {
        for (ChatAnnotation client : connections) {
        	broadcast("usi"+"0"+client.nickname_md5+client.nickname);
        }
    }
    
    private static void userout(String nickname_md5) {
    	broadcast("uso"+"0"+nickname_md5);
    }
}
