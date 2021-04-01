import React from 'react';
import clsx from 'clsx';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import useBaseUrl from '@docusaurus/useBaseUrl';
import styles from './styles.module.css';

const features = [
  {
    title: 'Entwickelt für Mathematische Inhalte',
    imageUrl: 'img/undraw_teaching.svg',
    description: (
      <>
       MaMpf (Mathematische Medienplattform) ist eine innovative Opensource  E-Learning-Plattform für das Mathematikstudium.
       Zentral ist die Verbindung zwischen verschiedenen Inhalten im Sinne eines Hypermediasystems.
      </>
    ),
  },
  {
    title: 'Hypermediaplattform',
    imageUrl: 'img/undraw_youtube_tutorial.svg',
    description: (
      <>
      MaMpf enthält seinen eigenen Hypermediaplayer und Editor (ThymE). ThymE nutzt die Struktur mathematischer Inhalte (unterteilt in Theoreme, Bemerkungen, Definitionen etc.) und erlaubt die Navigation zwischen verwandten, aber zeitlich getrennten Inhalten über die gesamte MaMpf-Datenbank hinaus.
      </>
    ),
  },
  {
    title: 'Hausaufgabenunterstützung',
    imageUrl: 'img/undraw_studying.svg',
    description: (
      <>
        MaMpf erlaubt die Verwaltung von Hausaufgaben für Studierende in Gruppen.
        Tutoren können Hausaufgaben Ihrer Gruppen korrigiert hochladen.
      </>
    ),
  },
];

function Feature({imageUrl, title, description}) {
  const imgUrl = useBaseUrl(imageUrl);
  return (
    <div className={clsx('col col--4', styles.feature)}>
      {imgUrl && (
        <div className="text--center">
          <img className={styles.featureImage} src={imgUrl} alt={title} />
        </div>
      )}
      <h3>{title}</h3>
      <p>{description}</p>
    </div>
  );
}

export default function Home() {
  const context = useDocusaurusContext();
  const {siteConfig = {}} = context;
  return (
    <Layout
      title={`Hello from ${siteConfig.title}`}
      description="Description will go into a meta tag in <head />">
      <header className={clsx('hero hero--primary', styles.heroBanner)}>
        <div className="container">
          <h1 className="hero__title">{siteConfig.title}</h1>
          <p className="hero__subtitle">{siteConfig.tagline}</p>
          <div className={styles.buttons}>
            <Link
              className={clsx(
                'button button--outline button--secondary button--lg',
                styles.getStarted,
              )}
              to={useBaseUrl('docs/')}>
              Get Started
            </Link>
          </div>
        </div>
      </header>
      <main>
        {features && features.length > 0 && (
          <section className={styles.features}>
            <div className="container">
              <div className="row">
                {features.map((props, idx) => (
                  <Feature key={idx} {...props} />
                ))}
              </div>
            </div>
          </section>
        )}
      </main>
    </Layout>
  );
}
