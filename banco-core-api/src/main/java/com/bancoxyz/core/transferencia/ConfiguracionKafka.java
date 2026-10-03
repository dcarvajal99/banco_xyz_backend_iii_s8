package com.bancoxyz.core.transferencia;

import org.apache.kafka.clients.admin.NewTopic;
import org.apache.kafka.common.TopicPartition;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.listener.DeadLetterPublishingRecoverer;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.util.backoff.FixedBackOff;

/**
 * Topicos que el core produce o consume, y el manejo de errores de sus consumidores.
 *
 * <p>La creacion automatica de topicos esta apagada en el broker: cada servicio declara los suyos. Declarar el mismo
 * topico desde dos servicios no hace dano (KafkaAdmin solo crea lo que falta).</p>
 */
@Configuration
@EnableScheduling
public class ConfiguracionKafka {

    @Bean
    public NewTopic topicoReservas(@Value("${banco.kafka.particiones:3}") int particiones) {
        return TopicBuilder.name(Topicos.RESERVAS).partitions(particiones).replicas(1).build();
    }

    @Bean
    public NewTopic topicoTransferencias(@Value("${banco.kafka.particiones:3}") int particiones) {
        return TopicBuilder.name(Topicos.TRANSFERENCIAS).partitions(particiones).replicas(1).build();
    }

    @Bean
    public NewTopic topicoSolicitadas(@Value("${banco.kafka.particiones:3}") int particiones) {
        return TopicBuilder.name(Topicos.SOLICITADAS).partitions(particiones).replicas(1).build();
    }

    @Bean
    public NewTopic topicoDecisiones(@Value("${banco.kafka.particiones:3}") int particiones) {
        return TopicBuilder.name(Topicos.DECISIONES).partitions(particiones).replicas(1).build();
    }

    @Bean
    public NewTopic dltSolicitadas(@Value("${banco.kafka.particiones:3}") int particiones) {
        return TopicBuilder.name(Topicos.SOLICITADAS + ".DLT").partitions(particiones).replicas(1).build();
    }

    @Bean
    public NewTopic dltDecisiones(@Value("${banco.kafka.particiones:3}") int particiones) {
        return TopicBuilder.name(Topicos.DECISIONES + ".DLT").partitions(particiones).replicas(1).build();
    }

    /**
     * Un evento que falla se reintenta dos veces con un segundo de espera (una base ocupada, un bloqueo) y despues se
     * publica en {@code <topico>.DLT} con el error en los encabezados, para no frenar la particion. Un mensaje ilegible
     * va directo al DLT: reintentarlo no lo va a arreglar.
     *
     * <p>El destino se fija explicitamente: Spring Kafka 3 publica por defecto en {@code <topico>-dlt}, un topico que no
     * existe con la creacion automatica apagada, y el mensaje se habria perdido.</p>
     */
    @Bean
    public DefaultErrorHandler manejadorDeErroresKafka(KafkaTemplate<String, String> kafka) {
        DeadLetterPublishingRecoverer alDlt = new DeadLetterPublishingRecoverer(kafka,
                (registro, error) -> new TopicPartition(registro.topic() + ".DLT", registro.partition()));
        DefaultErrorHandler manejador = new DefaultErrorHandler(alDlt, new FixedBackOff(1000L, 2L));
        manejador.addNotRetryableExceptions(EventoInvalido.class);
        return manejador;
    }
}
