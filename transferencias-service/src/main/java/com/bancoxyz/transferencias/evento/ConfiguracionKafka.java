package com.bancoxyz.transferencias.evento;

import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.common.TopicPartition;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.listener.DeadLetterPublishingRecoverer;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.util.backoff.FixedBackOff;

/** Topicos que este servicio produce o consume, y el manejo de errores de su consumidor (mismo criterio que el core). */
@Configuration
public class ConfiguracionKafka {

    @Bean
    public NewTopic topicoSolicitadas(@Value("${banco.kafka.particiones:3}") int particiones) {
        return TopicBuilder.name(Topicos.SOLICITADAS).partitions(particiones).replicas(1).build();
    }

    @Bean
    public NewTopic topicoReservas(@Value("${banco.kafka.particiones:3}") int particiones) {
        return TopicBuilder.name(Topicos.RESERVAS).partitions(particiones).replicas(1).build();
    }

    @Bean
    public NewTopic topicoTransferencias(@Value("${banco.kafka.particiones:3}") int particiones) {
        return TopicBuilder.name(Topicos.TRANSFERENCIAS).partitions(particiones).replicas(1).build();
    }

    @Bean
    public NewTopic dltReservas(@Value("${banco.kafka.particiones:3}") int particiones) {
        return TopicBuilder.name(Topicos.RESERVAS + ".DLT").partitions(particiones).replicas(1).build();
    }

    @Bean
    public NewTopic dltTransferencias(@Value("${banco.kafka.particiones:3}") int particiones) {
        return TopicBuilder.name(Topicos.TRANSFERENCIAS + ".DLT").partitions(particiones).replicas(1).build();
    }

    /** Dos reintentos con un segundo de espera y despues {@code <topico>.DLT}; un mensaje ilegible va directo. */
    @Bean
    public DefaultErrorHandler manejadorDeErroresKafka(KafkaTemplate<String, String> kafka) {
        DeadLetterPublishingRecoverer alDlt = new DeadLetterPublishingRecoverer(kafka,
                (registro, error) -> new TopicPartition(registro.topic() + ".DLT", registro.partition()));
        DefaultErrorHandler manejador = new DefaultErrorHandler(alDlt, new FixedBackOff(1000L, 2L));
        manejador.addNotRetryableExceptions(EventoInvalido.class);
        return manejador;
    }
}
