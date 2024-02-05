use async_trait::async_trait;
use ezsockets::CloseFrame;
use ezsockets::Error;
use ezsockets::Server;
use std::collections::HashMap;
use std::net::SocketAddr;

type SessionID = u8;
type Session = ezsockets::Session<SessionID, ()>;

#[derive(Debug)]
enum Message {
    Send { from: SessionID, text: String },
}

struct TaskServer {
    sessions: HashMap<SessionID, Session>,
    handle: Server<Self>,
}

#[async_trait]
impl ezsockets::ServerExt for TaskServer {
    type Call = Message;
    type Session = SessionActor;

    async fn on_connect(
        &mut self,
        socket: ezsockets::Socket,
        _request: ezsockets::Request,
        _address: SocketAddr,
    ) -> Result<Session, Option<CloseFrame>> {
        let id = (0..).find(|i| !self.sessions.contains_key(i)).unwrap_or(0);
        let session = Session::create(
            |session_handle| SessionActor {
                id,
                server: self.handle.clone(),
                session: session_handle,
            },
            id,
            socket,
        );
        self.sessions.insert(id, session.clone());
        Ok(session)
    }

    async fn on_disconnect(
        &mut self,
        id: <Self::Session as ezsockets::SessionExt>::ID,
        _reason: Result<Option<CloseFrame>, Error>,
    ) -> Result<(), Error> {
        assert!(self.sessions.remove(&id).is_some());

        Ok(())
    }

    async fn on_call(&mut self, call: Self::Call) -> Result<(), Error> {
        match call {
            Message::Send { from, text } => {
                let (ids, sessions): (Vec<SessionID>, Vec<&Session>) = self.sessions.iter().fold(
                    (Vec::new(), Vec::new()),
                    |(mut ids, mut sessions), (k, v)| {
                        if k != &from {
                            ids.push(*k);
                            sessions.push(v);
                        }
                        (ids, sessions)
                    },
                );
                tracing::info!(
                    "sending {text} to [{sessions}]",
                    sessions = ids
                        .iter()
                        .map(|id| id.to_string())
                        .collect::<Vec<_>>()
                        .join(",")
                );
                for session in sessions {
                    session.text(text.clone()).unwrap();
                }
            }
        };
        Ok(())
    }
}

struct SessionActor {
    id: SessionID,
    server: Server<TaskServer>,
    session: Session,
}

#[async_trait]
impl ezsockets::SessionExt for SessionActor {
    type ID = SessionID;
    type Call = ();

    fn id(&self) -> &Self::ID {
        &self.id
    }

    async fn on_text(&mut self, text: String) -> Result<(), Error> {
        tracing::info!("received: {text}");
        self.server
            .call(Message::Send {
                text,
                from: self.id,
            })
            .unwrap();
        Ok(())
    }

    async fn on_binary(&mut self, bytes: Vec<u8>) -> Result<(), Error> {
        // echo bytes back (we use this for a hacky ping/pong protocol for the wasm client demo)
        tracing::info!("echoing bytes: {bytes:?}");
        self.session.binary("pong".as_bytes())?;
        Ok(())
    }

    async fn on_call(&mut self, call: Self::Call) -> Result<(), Error> {
        let () = call;
        Ok(())
    }
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();
    let (server, _) = Server::create(|handle| TaskServer {
        sessions: HashMap::new(),
        handle,
    });
    ezsockets::tungstenite::run(server, "0.0.0.0:8080")
        .await
        .unwrap();
}
