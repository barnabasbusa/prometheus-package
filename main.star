CONFIG_DIR = "/config"
CONFIG_FILENAME = "prometheus-config.yml"
DEFAULT_SCRAPE_INTERVAL = "15s"


def run(
    plan,
    metrics_jobs=[],
    name="prometheus",
    min_cpu=10,
    max_cpu=1000,
    min_memory=128,
    max_memory=2048,
    node_selectors=None,
    storage_tsdb_retention_time="1d",
    storage_tsdb_retention_size="512MB",
    image="",
):
    """Starts a Prometheus server that scrapes metrics off the provided prometheus metrics configurations.

    Args:
        metrics_jobs(json): A list of prometheus metrics configs to scrape metrics from.
           More info on scrape config here: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config
           eg.
           ```
           metrics_jobs: [
                {
                    # name of metrics job
                    Name: "" ,

                    # endpoint to scrape metrics from,eg. <services ip address>:<exposed metrics port>
                    Endpoint: "",

                    # labels to associate with scraped metrics (eg. { "service_type": "api" } )
                    # optional
                    Labels:{},

                    # http path to scrape metrics from
                    # optional
                    MetricsPath: "/metrics",

                    # how frequently to scrape targets from this job
                    # optional
                    ScrapeInterval: "15s",

                    # fallback protocol to use if a scrape returns blank, unparseable, or otherwise invalid Content-Type
                    # optional
                    FallbackScrapeProtocol: "PrometheusText0.0.4"
                },
                {
                    ...
                },
            ]
           ```
        name(string): name of the prometheus service
        storage_tsdb_retention_time(string): retention time for prometheus instance (default: 1d)
        storage_tsdb_retention_size(string): retention size for prometheus instance (default: 512MB)
        min_cpu(int): min cpu for prometheus instance (default: 10 milicores)
        max_cpu(int): max cpu for prometheus instance (default: 1000 milicores)
        min_memory(int): min memory for prometheus instance (default: 128MB)
        max_memory(int): max memory for prometheus instance (default: 2048MB)
        node_selectors (dict[string, string]): Define a dict of node selectors - only works in kubernetes example: {"kubernetes.io/hostname": node-name-01}
    Returns:
        prometheus_url: endpoint to prometheus service inside the enclave (eg. 123.123.212:9090)
    """
    prometheus_config_template = read_file(src="./static-files/prometheus.yml.tmpl")

    prometheus_config_data = {"MetricsJobs": get_metrics_jobs(metrics_jobs)}

    prom_config_files_artifact = plan.render_templates(
        config={
            CONFIG_FILENAME: struct(
                template=prometheus_config_template,
                data=prometheus_config_data,
            )
        },
        name="prometheus-config",
    )

    config_file_path = CONFIG_DIR + "/" + CONFIG_FILENAME

    if node_selectors == None:
        node_selectors = {}

    if image=="":
        image="prom/prometheus:latest"

    prometheus_service = plan.add_service(
        name=name,
        config=ServiceConfig(
            image=image,
            ports={
                "http": PortSpec(
                    number=9090,
                    transport_protocol="TCP",
                    application_protocol="http",
                )
            },
            files={
                CONFIG_DIR: prom_config_files_artifact,
            },
            cmd=[
                "--config.file=" + config_file_path,
                "--storage.tsdb.path=/prometheus",
                "--storage.tsdb.retention.time=" + str(storage_tsdb_retention_time),
                "--storage.tsdb.retention.size=" + str(storage_tsdb_retention_size),
                "--storage.tsdb.wal-compression",
                "--web.console.libraries=/etc/prometheus/console_libraries",
                "--web.console.templates=/etc/prometheus/consoles",
                "--web.enable-lifecycle",
            ],
            min_cpu=min_cpu,
            max_cpu=max_cpu,
            min_memory=min_memory,
            max_memory=max_memory,
            node_selectors=node_selectors,
        ),
    )

    prometheus_service_ip_address = prometheus_service.ip_address
    prometheus_service_http_port = prometheus_service.ports["http"].number

    return "http://{0}:{1}".format(
        prometheus_service_ip_address, prometheus_service_http_port
    )


def get_metrics_jobs(service_metrics_configs):
    metrics_jobs = []
    for metrics_config in service_metrics_configs:
        if "Name" not in metrics_config:
            fail("Name not provided in metrics config.")
        if "Endpoint" not in metrics_config:
            fail("Endpoint not provided in metrics config")

        labels = {}
        if "Labels" in metrics_config:
            labels = metrics_config["Labels"]

        metrics_path = "/metrics"
        if "MetricsPath" in metrics_config:
            metrics_path = metrics_config["MetricsPath"]

        scrape_interval = DEFAULT_SCRAPE_INTERVAL
        if "ScrapeInterval" in metrics_config:
            scrape_interval = metrics_config["ScrapeInterval"]

        fallback_scrape_interval = "PrometheusText0.0.4"
        if "FallbackScrapeProtocol" in metrics_config:
            fallback_scrape_interval = metrics_config["FallbackScrapeProtocol"]

        metrics_jobs.append(
            {
                "Name": metrics_config["Name"],
                "Endpoint": metrics_config["Endpoint"],
                "Labels": labels,
                "MetricsPath": metrics_path,
                "ScrapeInterval": scrape_interval,
                "FallbackScrapeProtocol": fallback_scrape_interval,
            }
        )

    return metrics_jobs
