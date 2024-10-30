use futures::future::Remote;
use futures::FutureExt;
use getopts::Options;
use std::env;
use std::error::Error;
use std::net::SocketAddr;
use std::sync::atomic::{AtomicBool, Ordering};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::{TcpListener, TcpStream};
use tokio::sync::broadcast;

type BoxedError = Box<dyn std::error::Error + Sync + Send + 'static>;
static DEBUG: AtomicBool = AtomicBool::new(true);
const BUF_SIZE: usize = 1024;

#[derive(Clone, Debug)]
struct RemoteParameters {
    serviceName: String,
    password: String,
}

fn print_usage(program: &str, opts: Options) {
    let program_path = std::path::PathBuf::from(program);
    let program_name = program_path.file_stem().unwrap().to_string_lossy();
    let brief = format!(
        "Usage: {} REMOTE_HOST:PORT [-b BIND_ADDR] [-l LOCAL_PORT] [-s SVC_NAME] [-p SVC_PASSWORD]",
        program_name
    );
    print!("{}", opts.usage(&brief));
}

#[tokio::main]
async fn main() -> Result<(), BoxedError> {
    let args: Vec<String> = env::args().collect();
    let program = args[0].clone();
    let mut opts = Options::new();
    opts.optopt(
        "b",
        "bind",
        "The address on which to listen for incoming requests, defaulting to localhost",
        "BIND_ADDR",
    );
    opts.optopt(
        "l",
        "local-port",
        "The local port to which tcpproxy should bind to, randomly chosen otherwise",
        "LOCAL_PORT",
    );

    opts.optopt(
        "s",
        "service-name",
        "the name of the service to pass to the remote side",
        "SVC_NAME",
    );
    opts.optopt(
        "p",
        "password",
        "password to pass to the remote service",
        "SVC_PASSWORD",
    );
    opts.optflag("d", "debug", "Enable debug mode");

    let matches = match opts.parse(&args[1..]) {
        Ok(opts) => opts,
        Err(e) => {
            eprintln!("{}", e);
            print_usage(&program, opts);
            std::process::exit(-1);
        }
    };
    let remote = match matches.free.len() {
        1 => matches.free[0].as_str(),
        _ => {
            print_usage(&program, opts);
            std::process::exit(-1);
        }
    };

    if !remote.contains(':') {
        eprintln!("A remote port is required (REMOTE_ADDR:PORT)");
        std::process::exit(-1);
    }

    DEBUG.store(matches.opt_present("d"), Ordering::Relaxed);
    // let local_port: i32 = matches.opt_str("l").unwrap_or("0".to_string()).parse()?;
    let local_port: i32 = matches.opt_str("l").map(|s| s.parse()).unwrap_or(Ok(0))?;
    let bind_addr = match matches.opt_str("b") {
        Some(addr) => addr,
        None => "0.0.0.0".to_owned(),
    };

    let service = match matches.opt_str("s") {
        Some(s) => s,
        None => "frontend".to_owned(),
    };

    let password = match matches.opt_str("p") {
        Some(p) => p,
        None => "password".to_owned(),
    };

    let params = std::sync::Arc::new(RemoteParameters {
        serviceName: service,
        password: password,
    });

    forward(&bind_addr, local_port, remote, params).await
}

async fn forward(
    bind_ip: &str,
    local_port: i32,
    remote: &str,
    params: std::sync::Arc<RemoteParameters>,
) -> Result<(), BoxedError> {
    // Listen on the specified IP and port
    let bind_addr = if !bind_ip.starts_with('[') && bind_ip.contains(':') {
        // Correctly format for IPv6 usage
        format!("[{}]:{}", bind_ip, local_port)
    } else {
        format!("{}:{}", bind_ip, local_port)
    };
    let bind_sock = bind_addr
        .parse::<std::net::SocketAddr>()
        .expect("Failed to parse bind address");
    let listener = TcpListener::bind(&bind_sock).await?;
    println!("Listening on {}", listener.local_addr().unwrap());

    // We have either been provided an IP address or a host name.
    let remote = std::sync::Arc::new(remote.to_string());
    let Params = std::sync::Arc::clone(&params);
    async fn copy_with_abort<R, W>(
        read: &mut R,
        write: &mut W,
        mut abort: broadcast::Receiver<()>,
    ) -> tokio::io::Result<usize>
    where
        R: tokio::io::AsyncRead + Unpin,
        W: tokio::io::AsyncWrite + Unpin,
    {
        let mut copied = 0;
        let mut buf = [0u8; BUF_SIZE];
        loop {
            let bytes_read;
            tokio::select! {
                biased;

                result = read.read(&mut buf) => {
                    bytes_read = result?;
                },
                _ = abort.recv() => {
                    break;
                }
            }

            if bytes_read == 0 {
                break;
            }

            write.write_all(&buf[0..bytes_read]).await?;
            copied += bytes_read;
        }

        Ok(copied)
    }

    loop {
        let remote = remote.clone();
        let Params = params.clone();
        let (mut client, client_addr) = listener.accept().await?;

        tokio::spawn(async move {
            println!("New connection from {}", client_addr);

            let (mut client_read, mut client_write) = client.split();

            let valid = loop {
                let mut buf = [0; 107]; // 107 bytes is the longest possible v1 header
                let sequence: [u8; 2] = [0x0d, 0x0a];
                let sent_bytes = client_read.peek(&mut buf).await?;

                let position = buf
                    .windows(sequence.len())
                    .position(|window| window == sequence);

                match position {
                    None => {
                        if sent_bytes >= 107 {
                            break None;
                        }
                    }
                    Some(num) => {
                        let header = std::str::from_utf8(&buf[0..num]).unwrap().to_string();
                        break Some((num + 2, header));
                    }
                }
            };

            let toSend = match valid {
                None => {
                 None
		},
                Some(tuple) => {
		   
                    let mut readBuffer = [0; 107];
                    client_read.read_exact(&mut readBuffer[0..tuple.0]).await;
                    let parts = tuple.1.split(' ').collect::<Vec<&str>>();
		     if parts.len() != 6 {
                        println!("{} {}", file!(), line!());
                        None
                    } else {
                        let initial = format!(
                            "WEBIRC {} {} {} {} secure remote-port={} local-port={}",
                            Params.password,
                            Params.serviceName,
                            parts[2],
                            parts[2],
                            parts[4],
                            parts[5]
                        );
                        println!("{} {}", file!(), line!());

                        Some(initial)
                    }

                }
            };

            let str = toSend.unwrap();
            // WEBIRC pass gateway hostname ip secure remote-port local-port
            // Establish connection to upstream for each incoming client connection
            let mut remote = TcpStream::connect(remote.as_str()).await?;
            let (mut remote_read, mut remote_write) = remote.split();

            let _ = remote_write.write_all(str.as_bytes()).await?;

            let (cancel, _) = broadcast::channel::<()>(1);
            let (remote_copied, client_copied) = tokio::join! {
                copy_with_abort(&mut remote_read, &mut client_write, cancel.subscribe())
                    .then(|r| { let _ = cancel.send(()); async { r } }),
                copy_with_abort(&mut client_read, &mut remote_write, cancel.subscribe())
                    .then(|r| { let _ = cancel.send(()); async { r } }),
            };

            match client_copied {
                Ok(count) => {
                    if DEBUG.load(Ordering::Relaxed) {
                        eprintln!(
                            "Transferred {} bytes from remote client {} to upstream server",
                            count, client_addr
                        );
                    }
                }
                Err(err) => {
                    eprintln!(
                        "Error writing bytes from remote client {} to upstream server",
                        client_addr
                    );
                    eprintln!("{}", err);
                }
            };

            match remote_copied {
                Ok(count) => {
                    if DEBUG.load(Ordering::Relaxed) {
                        eprintln!(
                            "Transferred {} bytes from upstream server to remote client {}",
                            count, client_addr
                        );
                    }
                }
                Err(err) => {
                    eprintln!(
                        "Error writing from upstream server to remote client {}!",
                        client_addr
                    );
                    eprintln!("{}", err);
                }
            };

            let r: Result<(), BoxedError> = Ok(());
            r
        });
    }
}
