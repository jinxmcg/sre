import datetime


# TODO: implement the autoscaler here


def format_date_camunda(date_time: datetime.datetime) -> str:
    """
    Returns a date time string for a using in a REST API call to Camunda Engine
    + is NOT URL-escaped

    Args:
        date_time: datetime.datetime object to convert

    Returns:
        str: String in the yyyy-MM-ddTHH:mm:ss.SSSZ format

    Example:
        date_time: datetime.datetime(2021, 1, 31, 12, 34, 56, 789000,
            tzinfo=datetime.timezone(datetime.timedelta(seconds=3600), 'CEST'))
        returns: 2021-01-31T12:34:56.789+0100
    """
    date = date_time.astimezone().isoformat(sep='T', timespec='milliseconds')
    return ''.join(date.rsplit(':', 1))


def main():
    pass


if __name__ == '__main__':
    main()
