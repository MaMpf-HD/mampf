import React from 'react';
import clsx from 'clsx';
import Layout from '@theme/Layout';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import useBaseUrl from '@docusaurus/useBaseUrl';
import styles from './styles.module.css';

const features = [
  {
    title: 'Built for mathematical sciences',
    imageUrl: 'img/undraw_teaching.svg',
    description: (
      <>
       MaMpf (Mathematische Medienplattform) is an innovative open source E-Learning platform for the mathematical sciences.
        Central point is the interconnection between different content in the sense of a hypermedia system.
      </>
    ),
  },
  {
    title: 'Hypermedia plattform',
    imageUrl: 'img/undraw_youtube_tutorial.svg',
    description: (
      <>
        MaMpf comes with its own hypermedia player and editor THymE (The hypermedia Experience). ThymeE uses the internal structure of mathematical content (consisting of theorems, remarks, definitions etc.) and allows exact navigation between content that is related, but temporally apart. References can be created not only to content within the same video, but within the whole MaMpf database.
      </>
    ),
  },
  {
    title: 'Homework support',
    imageUrl: 'img/undraw_studying.svg',
    description: (
      <>
        MaMpf allows managing homework for classes and submissions by students.
        Tutors can upload solutions foreach individual student.
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
